import SwiftUI
import UniformTypeIdentifiers
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

private enum LibrarySection: String, CaseIterable, Identifiable {
    case library
    case recent
    case history

    var id: Self { self }

    var title: String {
        switch self {
        case .library: return "资料库"
        case .recent: return "最近播放"
        case .history: return "播放历史"
        }
    }

    var systemImage: String {
        switch self {
        case .library: return "books.vertical"
        case .recent: return "play.circle"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

private enum LibrarySort: String, CaseIterable, Identifiable {
    case title
    case dateAdded
    case lastPlayed

    var id: Self { self }

    var title: String {
        switch self {
        case .title: return "名称"
        case .dateAdded: return "导入时间"
        case .lastPlayed: return "最近播放"
        }
    }
}

private enum LibraryImportKind {
    case mp3Files
    case mp3Folder
    case pdfFilesOrFolders

    var allowedContentTypes: [UTType] {
        switch self {
        case .mp3Files:
            return [.mp3]
        case .mp3Folder:
            return [.folder]
        case .pdfFilesOrFolders:
            return [.pdf, .folder]
        }
    }

    var allowsMultipleSelection: Bool {
        self != .mp3Folder
    }
}

struct LibraryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var player: PlayerController
    @EnvironmentObject private var library: LibraryStore

    @State private var selectedSection: LibrarySection? = .library
    @State private var selectedBookID: UUID?
    @State private var searchText = ""
    @State private var sortOrder: LibrarySort = .title
    @State private var importKind: LibraryImportKind = .mp3Files
    @State private var showingImporter = false
    @State private var isImporting = false
    @State private var importErrorMessage: String?
    @State private var pdfAssociationMessage: String?
    @State private var bookPendingDeletion: Audiobook?

    init() {}

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(min: 360, ideal: 560)
        } detail: {
            detailColumn
        }
        .frame(minWidth: 960, minHeight: 620)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.hasLoadedChapter {
                PlayerBar()
                    .environmentObject(player)
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索书名、作者或章节")
        .toolbar { toolbarContent }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: importKind.allowedContentTypes,
            allowsMultipleSelection: importKind.allowsMultipleSelection,
            onCompletion: handleImport
        )
        .alert("无法完成操作", isPresented: errorIsPresented) {
            Button("好", role: .cancel) {
                importErrorMessage = nil
                player.errorMessage = nil
                library.errorMessage = nil
            }
        } message: {
            Text(activeErrorMessage ?? "发生未知错误。")
        }
        .alert("PDF 关联结果", isPresented: pdfAssociationIsPresented) {
            Button("好", role: .cancel) {
                pdfAssociationMessage = nil
            }
        } message: {
            Text(pdfAssociationMessage ?? "关联完成。")
        }
        .confirmationDialog(
            "从资料库移除“\(bookPendingDeletion?.title ?? "")”？",
            isPresented: deletionIsPresented,
            titleVisibility: .visible
        ) {
            Button("移除", role: .destructive) {
                if let book = bookPendingDeletion {
                    delete(book)
                }
                bookPendingDeletion = nil
            }
            Button("取消", role: .cancel) {
                bookPendingDeletion = nil
            }
        } message: {
            Text("只会移除 AudioShelf 中的索引和播放进度，不会删除原 MP3。")
        }
        .overlay {
            if isImporting {
                ZStack {
                    Color.black.opacity(0.12).ignoresSafeArea()
                    ProgressView("正在读取文件…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                player.persistProgress(force: true)
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selectedSection) {
            Section("资料库") {
                ForEach(LibrarySection.allCases) { section in
                    HStack(spacing: 8) {
                        Label(section.title, systemImage: section.systemImage)
                        Spacer()
                        Text("\(sectionCount(section))")
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                        .tag(Optional(section))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AudioShelf")
    }

    @ViewBuilder
    private var contentColumn: some View {
        if selectedSection == .history {
            HistoryListView(records: filteredHistory) { bookID in
                if books.contains(where: { $0.id == bookID }) {
                    selectedBookID = bookID
                    selectedSection = .library
                }
            }
            .navigationTitle("播放历史")
        } else if books.isEmpty && searchText.isEmpty {
            ContentUnavailableView {
                Label("资料库为空", systemImage: "books.vertical")
            } description: {
                Text("导入本地 MP3 或包含章节的文件夹开始使用。")
            } actions: {
                HStack {
                    Button("导入 MP3") { presentImporter(.mp3Files) }
                    Button("导入文件夹") { presentImporter(.mp3Folder) }
                        .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle(selectedSection?.title ?? "资料库")
        } else {
            BookGridView(
                books: visibleBooks,
                selectedBookID: $selectedBookID,
                onPlay: { player.continueBook($0, store: library) },
                onDelete: { bookPendingDeletion = $0 }
            )
            .navigationTitle(selectedSection?.title ?? "资料库")
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let selectedBook {
            BookDetailView(book: selectedBook)
                .environmentObject(player)
                .environmentObject(library)
        } else {
            ContentUnavailableView(
                "选择一本有声书",
                systemImage: "book.closed",
                description: Text("在资料库中选择封面以查看章节。")
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                Picker("排序方式", selection: $sortOrder) {
                    ForEach(LibrarySort.allCases) { order in
                        Text(order.title).tag(order)
                    }
                }
            } label: {
                Label("排序", systemImage: "arrow.up.arrow.down")
            }

            Menu {
                Button {
                    presentImporter(.mp3Files)
                } label: {
                    Label("导入 MP3…", systemImage: "music.note")
                }
                Button {
                    presentImporter(.mp3Folder)
                } label: {
                    Label("导入文件夹…", systemImage: "folder")
                }
                Divider()
                Button {
                    presentImporter(.pdfFilesOrFolders)
                } label: {
                    Label("关联 PDF 文件或文件夹…", systemImage: "doc.richtext")
                }
            } label: {
                Label("导入", systemImage: "plus")
            }
            .disabled(isImporting)
        }
    }

    private var selectedBook: Audiobook? {
        guard let selectedBookID else { return nil }
        return books.first { $0.id == selectedBookID }
    }

    private var books: [Audiobook] {
        library.books
    }

    private var history: [PlaybackRecord] {
        library.history.sorted { $0.startedAt > $1.startedAt }
    }

    private func sectionCount(_ section: LibrarySection) -> Int {
        switch section {
        case .library:
            return books.count
        case .recent:
            return books.filter { $0.lastPlayedAt != nil }.count
        case .history:
            return history.count
        }
    }

    private var visibleBooks: [Audiobook] {
        let sectionFiltered: [Audiobook]
        if selectedSection == .recent {
            sectionFiltered = books.filter { $0.lastPlayedAt != nil }
        } else {
            sectionFiltered = books
        }

        let searchFiltered = sectionFiltered.filter { book in
            guard !searchText.isEmpty else { return true }
            return book.title.localizedCaseInsensitiveContains(searchText)
                || book.author?.localizedCaseInsensitiveContains(searchText) == true
                || book.chapters.contains { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        if selectedSection == .recent {
            return searchFiltered.sorted {
                ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast)
            }
        }

        switch sortOrder {
        case .title:
            return searchFiltered.sorted { NaturalSort.isOrderedBefore($0.title, $1.title) }
        case .dateAdded:
            return searchFiltered.sorted { $0.importedAt > $1.importedAt }
        case .lastPlayed:
            return searchFiltered.sorted {
                ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast)
            }
        }
    }

    private var filteredHistory: [PlaybackRecord] {
        guard !searchText.isEmpty else { return history }
        return history.filter {
            $0.bookTitle.localizedCaseInsensitiveContains(searchText)
                || $0.chapterTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var activeErrorMessage: String? {
        importErrorMessage ?? player.errorMessage ?? library.errorMessage
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { activeErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                    player.errorMessage = nil
                    library.errorMessage = nil
                }
            }
        )
    }

    private var deletionIsPresented: Binding<Bool> {
        Binding(
            get: { bookPendingDeletion != nil },
            set: { isPresented in
                if !isPresented { bookPendingDeletion = nil }
            }
        )
    }

    private var pdfAssociationIsPresented: Binding<Bool> {
        Binding(
            get: { pdfAssociationMessage != nil },
            set: { isPresented in
                if !isPresented { pdfAssociationMessage = nil }
            }
        )
    }

    private func presentImporter(_ kind: LibraryImportKind) {
        importKind = kind
        showingImporter = true
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch importKind {
        case .mp3Files:
            handleFileImport(result)
        case .mp3Folder:
            handleFolderImport(result)
        case .pdfFilesOrFolders:
            handlePDFImport(result)
        }
    }

    private func handleFolderImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            Task { @MainActor in
                defer { isImporting = false }
                do {
                    let book = try await LibraryImporter.importFolder(url, into: library)
                    selectedBookID = book.id
                    selectedSection = .library
                } catch {
                    importErrorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            isImporting = true
            Task { @MainActor in
                defer { isImporting = false }
                do {
                    let imported = try await LibraryImporter.importFiles(urls, into: library)
                    selectedBookID = imported.first?.id
                    selectedSection = .library
                } catch {
                    importErrorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            isImporting = true
            Task { @MainActor in
                defer { isImporting = false }
                do {
                    let association = try PDFService.associate(
                        selectedURLs: urls,
                        with: books,
                        store: library
                    )
                    if let matchedBook = association.matchedBooks.first {
                        selectedBookID = matchedBook.id
                        selectedSection = .library
                    }
                    pdfAssociationMessage = association.message
                } catch {
                    importErrorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }

    private func delete(_ book: Audiobook) {
        player.stopIfPlaying(bookID: book.id)
        if selectedBookID == book.id {
            selectedBookID = nil
        }
        do {
            try library.remove(book)
        } catch {
            selectedBookID = book.id
            importErrorMessage = "无法更新资料库：\(error.localizedDescription)"
        }
    }
}
