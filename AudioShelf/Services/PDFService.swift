import AppKit
import Foundation
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

struct PDFAssociationResult {
    let matchedBooks: [Audiobook]
    let unmatchedFileNames: [String]
    let ambiguousFileNames: [String]

    var message: String {
        var parts = ["已关联 \(matchedBooks.count) 本有声书。"]
        if !unmatchedFileNames.isEmpty {
            parts.append("未找到同名书籍：\(unmatchedFileNames.joined(separator: "、"))")
        }
        if !ambiguousFileNames.isEmpty {
            parts.append("存在同名冲突：\(ambiguousFileNames.joined(separator: "、"))")
        }
        return parts.joined(separator: "\n")
    }
}

enum PDFServiceError: LocalizedError {
    case missingAssociation
    case noPDFFiles(String)
    case invalidPDF(String)
    case fileNoLongerExists(String)
    case cannotOpen(String)

    var errorDescription: String? {
        switch self {
        case .missingAssociation:
            return "这本书尚未关联 PDF。"
        case .noPDFFiles(let name):
            return "“\(name)”中没有找到 PDF 文件。"
        case .invalidPDF(let name):
            return "“\(name)”不是可用的 PDF 文件。"
        case .fileNoLongerExists(let name):
            return "找不到 PDF“\(name)”。文件可能已被移动或删除。"
        case .cannotOpen(let name):
            return "系统无法打开 PDF“\(name)”。"
        }
    }
}

@MainActor
enum PDFService {
    static func candidateNames(for book: Audiobook) -> [String] {
        var names = [
            book.title,
            URL(fileURLWithPath: book.sourcePathHint).lastPathComponent
        ]
        if book.chapters.count == 1, let chapter = book.chapters.first {
            names.append(chapter.relativePath)
        }
        return names
    }

    static func attach(_ pdfURL: URL, to book: Audiobook) throws {
        guard pdfURL.pathExtension.lowercased() == "pdf" else {
            throw PDFServiceError.invalidPDF(pdfURL.lastPathComponent)
        }
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            throw PDFServiceError.fileNoLongerExists(pdfURL.lastPathComponent)
        }
        book.pdfBookmark = try BookmarkService.makeBookmark(for: pdfURL)
        book.pdfFileName = pdfURL.lastPathComponent
    }

    static func associate(
        selectedURLs: [URL],
        with books: [Audiobook],
        store: LibraryStore
    ) throws -> PDFAssociationResult {
        var accessedURLs: [URL] = []
        for url in selectedURLs where url.startAccessingSecurityScopedResource() {
            accessedURLs.append(url)
        }
        defer {
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var discoveredURLs: [URL] = []
        for url in selectedURLs {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true || url.hasDirectoryPath {
                discoveredURLs.append(contentsOf: pdfFiles(in: url))
            } else if url.pathExtension.lowercased() == "pdf" {
                discoveredURLs.append(url)
            }
        }

        var seenPaths = Set<String>()
        let pdfURLs = discoveredURLs
            .filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
            .sorted { NaturalSort.isOrderedBefore($0.path, $1.path) }
        guard !pdfURLs.isEmpty else {
            let selectionName = selectedURLs.count == 1
                ? selectedURLs[0].lastPathComponent
                : "所选项目"
            throw PDFServiceError.noPDFFiles(selectionName)
        }

        return try associate(pdfURLs: pdfURLs, with: books, store: store)
    }

    static func associate(
        pdfURLs: [URL],
        with books: [Audiobook],
        store: LibraryStore
    ) throws -> PDFAssociationResult {
        var unmatched: [String] = []
        var ambiguous: [String] = []
        var candidates: [(url: URL, book: Audiobook)] = []

        for pdfURL in pdfURLs where pdfURL.pathExtension.lowercased() == "pdf" {
            let matches = books.filter {
                PDFMatching.matches(
                    pdfFileName: pdfURL.lastPathComponent,
                    candidateNames: candidateNames(for: $0)
                )
            }
            if matches.count == 1, let book = matches.first {
                candidates.append((pdfURL, book))
            } else if matches.isEmpty {
                unmatched.append(pdfURL.lastPathComponent)
            } else {
                ambiguous.append(pdfURL.lastPathComponent)
            }
        }

        let grouped = Dictionary(grouping: candidates, by: { $0.book.id })
        var uniqueCandidates: [(url: URL, book: Audiobook)] = []
        for group in grouped.values {
            if group.count == 1, let candidate = group.first {
                uniqueCandidates.append(candidate)
            } else {
                ambiguous.append(contentsOf: group.map { $0.url.lastPathComponent })
            }
        }

        var previousValues: [(book: Audiobook, name: String?, bookmark: Data?)] = []
        do {
            for candidate in uniqueCandidates {
                let didStartAccess = candidate.url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccess {
                        candidate.url.stopAccessingSecurityScopedResource()
                    }
                }
                previousValues.append(
                    (candidate.book, candidate.book.pdfFileName, candidate.book.pdfBookmark)
                )
                try attach(candidate.url, to: candidate.book)
            }
            if !uniqueCandidates.isEmpty {
                try store.save()
            }
        } catch {
            for previous in previousValues {
                previous.book.pdfFileName = previous.name
                previous.book.pdfBookmark = previous.bookmark
            }
            throw error
        }

        return PDFAssociationResult(
            matchedBooks: uniqueCandidates.map(\.book),
            unmatchedFileNames: unmatched.sorted(),
            ambiguousFileNames: ambiguous.sorted()
        )
    }

    static func openPDF(for book: Audiobook, store: LibraryStore) throws {
        guard let bookmark = book.pdfBookmark else {
            throw PDFServiceError.missingAssociation
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFServiceError.fileNoLongerExists(book.pdfFileName ?? url.lastPathComponent)
        }
        if isStale {
            book.pdfBookmark = try BookmarkService.makeBookmark(for: url)
            try store.save()
        }
        guard NSWorkspace.shared.open(url) else {
            throw PDFServiceError.cannotOpen(book.pdfFileName ?? url.lastPathComponent)
        }
    }

    private static func pdfFiles(in folderURL: URL) -> [URL] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isHiddenKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension.lowercased() == "pdf" else { continue }
            let values = try? url.resourceValues(forKeys: keys)
            if values?.isRegularFile == true {
                urls.append(url)
            }
        }
        return urls
    }
}
