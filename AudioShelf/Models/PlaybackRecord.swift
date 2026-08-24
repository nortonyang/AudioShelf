import Foundation

final class PlaybackRecord: Codable, Identifiable {
    var id: UUID
    var bookID: UUID
    var chapterID: UUID
    var bookTitle: String
    var chapterTitle: String
    var startedAt: Date
    var updatedAt: Date
    var startPosition: Double
    var endPosition: Double
    var completed: Bool

    init(
        id: UUID = UUID(),
        bookID: UUID,
        chapterID: UUID,
        bookTitle: String,
        chapterTitle: String,
        startedAt: Date = Date(),
        updatedAt: Date = Date(),
        startPosition: Double,
        endPosition: Double,
        completed: Bool = false
    ) {
        self.id = id
        self.bookID = bookID
        self.chapterID = chapterID
        self.bookTitle = bookTitle
        self.chapterTitle = chapterTitle
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.completed = completed
    }
}
