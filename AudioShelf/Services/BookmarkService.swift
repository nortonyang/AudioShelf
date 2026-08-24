import Foundation

struct ResolvedAudioResource {
    let audioURL: URL
    let scopeURL: URL
}

enum BookmarkServiceError: LocalizedError {
    case missingBookmark
    case fileNoLongerExists(String)

    var errorDescription: String? {
        switch self {
        case .missingBookmark:
            return "缺少文件访问授权。请在章节菜单中重新定位对应的 MP3。"
        case .fileNoLongerExists(let name):
            return "找不到“\(name)”。文件可能已被移动或删除，请在章节菜单中重新定位。"
        }
    }
}

enum BookmarkService {
    static func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    @MainActor
    static func resolve(chapter: Chapter, in book: Audiobook) throws -> ResolvedAudioResource {
        if let fileBookmark = chapter.fileBookmark {
            var isStale = false
            let fileURL = try URL(
                resolvingBookmarkData: fileBookmark,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            let didStartAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            if isStale {
                chapter.fileBookmark = try makeBookmark(for: fileURL)
            }
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw BookmarkServiceError.fileNoLongerExists(chapter.title)
            }
            return ResolvedAudioResource(audioURL: fileURL, scopeURL: fileURL)
        }

        guard let rootBookmark = book.rootBookmark else {
            throw BookmarkServiceError.missingBookmark
        }
        var isStale = false
        let rootURL = try URL(
            resolvingBookmarkData: rootBookmark,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        let didStartAccess = rootURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                rootURL.stopAccessingSecurityScopedResource()
            }
        }
        if isStale {
            book.rootBookmark = try makeBookmark(for: rootURL)
        }
        let audioURL = rootURL.appendingPathComponent(chapter.relativePath)
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw BookmarkServiceError.fileNoLongerExists(chapter.title)
        }
        return ResolvedAudioResource(audioURL: audioURL, scopeURL: rootURL)
    }
}
