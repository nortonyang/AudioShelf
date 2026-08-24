import Foundation

private func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("Store 检查失败：\(message)\n".utf8))
        exit(1)
    }
}

@main
private struct StoreChecks {
    @MainActor
    static func main() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioShelfStoreChecks-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let storageURL = temporaryDirectory.appendingPathComponent("library.json")
        let chapter = Chapter(
            title: "第1章",
            orderIndex: 0,
            relativePath: "01.mp3",
            duration: 123,
            fileBookmark: Data([1, 2, 3])
        )
        let book = Audiobook(
            title: "测试有声书",
            author: "测试作者",
            lastChapterID: chapter.id,
            playbackPosition: 42,
            totalDuration: 123,
            coverData: Data([4, 5, 6]),
            pdfFileName: "测试有声书.pdf",
            pdfBookmark: Data([7, 8, 9]),
            sourceType: .files,
            sourcePathHint: "/tmp",
            chapters: [chapter]
        )
        let record = PlaybackRecord(
            bookID: book.id,
            chapterID: chapter.id,
            bookTitle: book.title,
            chapterTitle: chapter.title,
            startPosition: 0,
            endPosition: 42
        )

        let store = LibraryStore(storageURL: storageURL)
        try store.add(book)
        store.appendHistory(record)
        try store.save()

        let reloaded = LibraryStore(storageURL: storageURL)
        check(reloaded.books.count == 1, "书籍数量")
        check(reloaded.history.count == 1, "历史数量")
        check(reloaded.books[0].id == book.id, "书籍 ID")
        check(reloaded.books[0].playbackPosition == 42, "播放进度")
        check(reloaded.books[0].coverData == Data([4, 5, 6]), "封面数据")
        check(reloaded.books[0].pdfFileName == "测试有声书.pdf", "PDF 文件名")
        check(reloaded.books[0].pdfBookmark == Data([7, 8, 9]), "PDF 书签")
        check(reloaded.books[0].chapters[0].fileBookmark == Data([1, 2, 3]), "章节书签")

        let storedData = try Data(contentsOf: storageURL)
        var legacyObject = try JSONSerialization.jsonObject(with: storedData) as? [String: Any]
        var legacyBooks = legacyObject?["books"] as? [[String: Any]] ?? []
        legacyBooks[0].removeValue(forKey: "pdfFileName")
        legacyBooks[0].removeValue(forKey: "pdfBookmark")
        legacyObject?["books"] = legacyBooks
        let legacyURL = temporaryDirectory.appendingPathComponent("legacy-library.json")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject ?? [:])
        try legacyData.write(to: legacyURL)
        let legacyStore = LibraryStore(storageURL: legacyURL)
        check(legacyStore.books.count == 1, "旧 JSON 兼容")
        check(legacyStore.books[0].pdfBookmark == nil, "旧 JSON PDF 默认值")
        print("AudioShelfStoreChecks：全部通过")
    }
}
