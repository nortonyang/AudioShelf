import SwiftUI
import UniformTypeIdentifiers
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

struct BookDetailView: View {
    @EnvironmentObject private var player: PlayerController
    @EnvironmentObject private var library: LibraryStore

    let book: Audiobook

    @State private var showingRelinkImporter = false
    @State private var chapterPendingRelink: Chapter?
    @State private var isRelinking = false
    @State private var relinkErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            chapterList
        }
        .navigationTitle(book.title)
        .fileImporter(
            isPresented: $showingRelinkImporter,
            allowedContentTypes: [.mp3],
            allowsMultipleSelection: false,
            onCompletion: handleRelink
        )
        .alert("无法重新定位章节", isPresented: relinkErrorIsPresented) {
            Button("好", role: .cancel) {
                relinkErrorMessage = nil
            }
        } message: {
            Text(relinkErrorMessage ?? "发生未知错误。")
        }
        .overlay {
            if isRelinking {
                ZStack {
                    Color.black.opacity(0.12).ignoresSafeArea()
                    ProgressView("正在更新章节…")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 22) {
            CoverView(title: book.title, artworkData: book.coverData)
                .frame(width: 164, height: 164)

            VStack(alignment: .leading, spacing: 11) {
                Text(book.title)
                    .font(.title.weight(.bold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let author = book.author {
                    Text(author)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    metadataPill("\(book.chapters.count) 章", systemImage: "list.number")
                    metadataPill(
                        TimeFormatting.durationDescription(book.totalDuration),
                        systemImage: "clock"
                    )
                }

                Label(sourceDescription, systemImage: "externaldrive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let pdfFileName = book.pdfFileName {
                    Label(pdfFileName, systemImage: "doc.richtext")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if book.overallProgress > 0 {
                    HStack {
                        Text("收听进度")
                        Spacer()
                        Text("\(Int((book.overallProgress * 100).rounded()))%")
                            .monospacedDigit()
                    }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: book.overallProgress)
                        .frame(maxWidth: 360)
                }

                HStack(spacing: 10) {
                    Button {
                        player.continueBook(book, store: library)
                    } label: {
                        Label(
                            book.overallProgress > 0 ? "继续播放" : "开始播放",
                            systemImage: "play.fill"
                        )
                        .frame(minWidth: 96)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(book.chapters.isEmpty)

                    if book.pdfBookmark != nil {
                        Button {
                            do {
                                try PDFService.openPDF(for: book, store: library)
                            } catch {
                                player.errorMessage = error.localizedDescription
                            }
                        } label: {
                            Label("打开 PDF", systemImage: "doc.richtext")
                        }
                        .controlSize(.large)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.075), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("章节")
                    .font(.title2.weight(.semibold))
                Text("\(book.chapters.count)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
                .padding(.horizontal, 24)
                .padding(.top, 16)

            List(book.sortedChapters) { chapter in
                let isCurrent = player.currentChapterID == chapter.id
                Button {
                    player.load(
                        book: book,
                        chapter: chapter,
                        store: library,
                        autoPlay: true,
                        resumeSavedPosition: chapter.id == book.lastChapterID
                    )
                } label: {
                    HStack(spacing: 12) {
                        Text("\(chapter.orderIndex + 1)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                isCurrent
                                    ? Color.accentColor.opacity(0.14)
                                    : Color.secondary.opacity(0.10),
                                in: Circle()
                            )

                        Image(systemName: isCurrent ?
                              (player.isPlaying ? "speaker.wave.2.fill" : "pause.circle.fill") :
                              "play.circle")
                            .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(chapter.title)
                                .lineLimit(1)
                                .foregroundStyle(.primary)

                            if chapter.id == book.lastChapterID, book.playbackPosition > 0 {
                                Text("上次听到 \(TimeFormatting.playbackTime(book.playbackPosition))")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(TimeFormatting.playbackTime(chapter.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 54, alignment: .trailing)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        isCurrent ? Color.accentColor.opacity(0.10) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 2, leading: 14, bottom: 2, trailing: 14))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contextMenu {
                    Button {
                        beginRelinking(chapter)
                    } label: {
                        Label("重新定位此章节…", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func metadataPill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.11), in: Capsule())
    }

    private var sourceDescription: String {
        let sourceName = URL(fileURLWithPath: book.sourcePathHint).lastPathComponent
        return book.sourceType == .folder ? "文件夹：\(sourceName)" : "本地文件：\(sourceName)"
    }

    private var relinkErrorIsPresented: Binding<Bool> {
        Binding(
            get: { relinkErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    relinkErrorMessage = nil
                }
            }
        )
    }

    private func beginRelinking(_ chapter: Chapter) {
        chapterPendingRelink = chapter
        showingRelinkImporter = true
    }

    private func handleRelink(_ result: Result<[URL], Error>) {
        guard let chapter = chapterPendingRelink else { return }
        chapterPendingRelink = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isRelinking = true
            Task { @MainActor in
                defer { isRelinking = false }
                do {
                    try await LibraryImporter.relink(
                        chapter: chapter,
                        to: url,
                        in: book,
                        store: library
                    )
                } catch {
                    relinkErrorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            relinkErrorMessage = error.localizedDescription
        }
    }
}
