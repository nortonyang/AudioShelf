import Foundation

final class Chapter: Codable, Identifiable {
    var id: UUID
    var title: String
    var orderIndex: Int
    var relativePath: String
    var duration: Double
    var fileBookmark: Data?

    init(
        id: UUID = UUID(),
        title: String,
        orderIndex: Int,
        relativePath: String,
        duration: Double = 0,
        fileBookmark: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.relativePath = relativePath
        self.duration = duration
        self.fileBookmark = fileBookmark
    }
}
