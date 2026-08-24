import Foundation
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

enum LibraryImportError: LocalizedError {
    case noMP3Files(String)
    case cannotRead(String)
    case invalidReplacement(String)

    var errorDescription: String? {
        switch self {
        case .noMP3Files(let name):
            return "“\(name)”中没有找到 MP3 文件。"
        case .cannotRead(let name):
            return "无法读取“\(name)”。请确认文件仍存在并重新授权。"
        case .invalidReplacement(let name):
            return "“\(name)”不是可用的 MP3 文件。"
        }
    }
}

@MainActor
enum LibraryImporter {
    static func importFolder(_ folderURL: URL, into store: LibraryStore) async throws -> Audiobook {
        let didStartAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        let urls = mp3Files(in: folderURL)
        guard !urls.isEmpty else {
            throw LibraryImportError.noMP3Files(folderURL.lastPathComponent)
        }

        let rootBookmark = try BookmarkService.makeBookmark(for: folderURL)
        let book = Audiobook(
            title: folderURL.lastPathComponent,
            rootBookmark: rootBookmark,
            sourceType: .folder,
            sourcePathHint: folderURL.path
        )

        var firstArtwork: Data?
        var firstArtist: String?
        var totalDuration = 0.0
        var chapters: [Chapter] = []

        for (index, fileURL) in urls.enumerated() {
            let metadata = try await MetadataService.read(from: fileURL)
            let title = nonEmpty(metadata.title) ?? fileURL.deletingPathExtension().lastPathComponent
            let relativePath = relativePath(of: fileURL, under: folderURL)
            chapters.append(
                Chapter(
                    title: title,
                    orderIndex: index,
                    relativePath: relativePath,
                    duration: metadata.duration
                )
            )
            totalDuration += metadata.duration
            if firstArtwork == nil { firstArtwork = metadata.artworkData }
            if firstArtist == nil { firstArtist = nonEmpty(metadata.artist) }
        }

        book.author = firstArtist
        book.coverData = firstArtwork
        book.totalDuration = totalDuration
        book.chapters = chapters
        if let pdfURL = matchingPDF(
            in: folderURL,
            candidateNames: PDFService.candidateNames(for: book)
        ) {
            try? PDFService.attach(pdfURL, to: book)
        }
        try store.add(book)
        return book
    }

    static func importFiles(_ fileURLs: [URL], into store: LibraryStore) async throws -> [Audiobook] {
        let mp3URLs = fileURLs.filter { $0.pathExtension.lowercased() == "mp3" }
        guard !mp3URLs.isEmpty else {
            throw LibraryImportError.noMP3Files("所选项目")
        }

        let groups = Dictionary(grouping: mp3URLs) {
            $0.deletingLastPathComponent().standardizedFileURL.path
        }
        var importedBooks: [Audiobook] = []

        for parentPath in groups.keys.sorted(by: NaturalSort.isOrderedBefore) {
            guard let group = groups[parentPath] else { continue }
            let urls = group.sorted { NaturalSort.isOrderedBefore($0.lastPathComponent, $1.lastPathComponent) }
            let book = try await makeBook(from: urls)
            importedBooks.append(book)
        }

        try store.add(contentsOf: importedBooks)
        return importedBooks
    }

    static func relink(
        chapter: Chapter,
        to fileURL: URL,
        in book: Audiobook,
        store: LibraryStore
    ) async throws {
        guard fileURL.pathExtension.lowercased() == "mp3" else {
            throw LibraryImportError.invalidReplacement(fileURL.lastPathComponent)
        }

        let didStartAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw LibraryImportError.cannotRead(fileURL.lastPathComponent)
        }

        let bookmark = try BookmarkService.makeBookmark(for: fileURL)
        let metadata = try await MetadataService.read(from: fileURL)

        chapter.fileBookmark = bookmark
        chapter.relativePath = fileURL.lastPathComponent
        if metadata.duration > 0 {
            chapter.duration = metadata.duration
        }
        book.totalDuration = book.chapters.reduce(0) { $0 + $1.duration }
        if book.coverData == nil {
            book.coverData = metadata.artworkData
        }
        if book.author == nil {
            book.author = nonEmpty(metadata.artist)
        }
        if book.chapters.count == 1 {
            book.sourcePathHint = fileURL.deletingLastPathComponent().path
        }
        try store.save()
    }

    private static func makeBook(from urls: [URL]) async throws -> Audiobook {
        guard let firstURL = urls.first else {
            throw LibraryImportError.noMP3Files("所选项目")
        }

        var metadataItems: [(url: URL, bookmark: Data, metadata: AudioMetadata)] = []
        for url in urls {
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw LibraryImportError.cannotRead(url.lastPathComponent)
            }
            let bookmark = try BookmarkService.makeBookmark(for: url)
            let metadata = try await MetadataService.read(from: url)
            metadataItems.append((url, bookmark, metadata))
        }

        let firstMetadata = metadataItems[0].metadata
        let fallbackTitle = urls.count == 1
            ? firstURL.deletingPathExtension().lastPathComponent
            : firstURL.deletingLastPathComponent().lastPathComponent
        let bookTitle = nonEmpty(firstMetadata.album) ?? fallbackTitle
        let book = Audiobook(
            title: bookTitle,
            author: metadataItems.lazy.compactMap { nonEmpty($0.metadata.artist) }.first,
            coverData: metadataItems.lazy.compactMap { $0.metadata.artworkData }.first,
            sourceType: .files,
            sourcePathHint: firstURL.deletingLastPathComponent().path
        )

        book.chapters = metadataItems.enumerated().map { index, item in
            Chapter(
                title: nonEmpty(item.metadata.title) ?? item.url.deletingPathExtension().lastPathComponent,
                orderIndex: index,
                relativePath: item.url.lastPathComponent,
                duration: item.metadata.duration,
                fileBookmark: item.bookmark
            )
        }
        book.totalDuration = book.chapters.reduce(0) { $0 + $1.duration }
        return book
    }

    private static func mp3Files(in folderURL: URL) -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isHiddenKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension.lowercased() == "mp3" else { continue }
            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isRegularFile == true {
                urls.append(url)
            }
        }
        return urls.sorted {
            NaturalSort.isOrderedBefore(
                relativePath(of: $0, under: folderURL),
                relativePath(of: $1, under: folderURL)
            )
        }
    }

    private static func matchingPDF(in folderURL: URL, candidateNames: [String]) -> URL? {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isHiddenKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return nil
        }

        var matches: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension.lowercased() == "pdf",
                  PDFMatching.matches(
                    pdfFileName: url.lastPathComponent,
                    candidateNames: candidateNames
                  ) else { continue }
            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isRegularFile == true {
                matches.append(url)
            }
        }
        return matches.sorted {
            NaturalSort.isOrderedBefore(
                relativePath(of: $0, under: folderURL),
                relativePath(of: $1, under: folderURL)
            )
        }.first
    }

    private static func relativePath(of fileURL: URL, under folderURL: URL) -> String {
        let root = folderURL.standardizedFileURL.path
        let file = fileURL.standardizedFileURL.path
        guard file.hasPrefix(root + "/") else { return fileURL.lastPathComponent }
        return String(file.dropFirst(root.count + 1))
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
