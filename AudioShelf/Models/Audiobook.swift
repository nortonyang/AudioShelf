import Foundation
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

enum AudiobookSourceType: String, Codable {
    case folder
    case files
}

final class Audiobook: Codable, Identifiable {
    var id: UUID
    var title: String
    var author: String?
    var importedAt: Date
    var lastPlayedAt: Date?
    var lastChapterID: UUID?
    var playbackPosition: Double
    var totalDuration: Double
    var completedAt: Date?
    var coverData: Data?
    var rootBookmark: Data?
    var pdfFileName: String?
    var pdfBookmark: Data?
    var sourceTypeRawValue: String
    var sourcePathHint: String

    var chapters: [Chapter]

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        importedAt: Date = Date(),
        lastPlayedAt: Date? = nil,
        lastChapterID: UUID? = nil,
        playbackPosition: Double = 0,
        totalDuration: Double = 0,
        completedAt: Date? = nil,
        coverData: Data? = nil,
        rootBookmark: Data? = nil,
        pdfFileName: String? = nil,
        pdfBookmark: Data? = nil,
        sourceType: AudiobookSourceType,
        sourcePathHint: String,
        chapters: [Chapter] = []
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.importedAt = importedAt
        self.lastPlayedAt = lastPlayedAt
        self.lastChapterID = lastChapterID
        self.playbackPosition = playbackPosition
        self.totalDuration = totalDuration
        self.completedAt = completedAt
        self.coverData = coverData
        self.rootBookmark = rootBookmark
        self.pdfFileName = pdfFileName
        self.pdfBookmark = pdfBookmark
        self.sourceTypeRawValue = sourceType.rawValue
        self.sourcePathHint = sourcePathHint
        self.chapters = chapters
    }

    var sourceType: AudiobookSourceType {
        get { AudiobookSourceType(rawValue: sourceTypeRawValue) ?? .files }
        set { sourceTypeRawValue = newValue.rawValue }
    }

    var sortedChapters: [Chapter] {
        chapters.sorted {
            if $0.orderIndex != $1.orderIndex {
                return $0.orderIndex < $1.orderIndex
            }
            return NaturalSort.isOrderedBefore($0.title, $1.title)
        }
    }

    var currentChapter: Chapter? {
        guard let lastChapterID else { return sortedChapters.first }
        return chapters.first { $0.id == lastChapterID } ?? sortedChapters.first
    }

    var overallProgress: Double {
        guard totalDuration > 0 else { return 0 }
        let ordered = sortedChapters
        guard let lastChapterID,
              let currentIndex = ordered.firstIndex(where: { $0.id == lastChapterID }) else {
            return 0
        }
        let completedDuration = ordered.prefix(currentIndex).reduce(0) { $0 + $1.duration }
        return min(max((completedDuration + playbackPosition) / totalDuration, 0), 1)
    }
}
