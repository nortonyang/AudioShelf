import Combine
import Foundation

private struct LibrarySnapshot: Codable {
    let schemaVersion: Int
    let books: [Audiobook]
    let history: [PlaybackRecord]
}

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var books: [Audiobook] = []
    @Published private(set) var history: [PlaybackRecord] = []
    @Published var errorMessage: String?

    let storageURL: URL

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        load()
    }

    func add(_ book: Audiobook) throws {
        books.append(book)
        do {
            try save()
        } catch {
            books.removeAll { $0.id == book.id }
            throw error
        }
    }

    func add(contentsOf newBooks: [Audiobook]) throws {
        books.append(contentsOf: newBooks)
        do {
            try save()
        } catch {
            let insertedIDs = Set(newBooks.map(\.id))
            books.removeAll { insertedIDs.contains($0.id) }
            throw error
        }
    }

    func remove(_ book: Audiobook) throws {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        let removed = books.remove(at: index)
        do {
            try save()
        } catch {
            books.insert(removed, at: index)
            throw error
        }
    }

    func appendHistory(_ record: PlaybackRecord) {
        history.insert(record, at: 0)
    }

    func save() throws {
        objectWillChange.send()
        let directory = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let snapshot = LibrarySnapshot(
            schemaVersion: 1,
            books: books,
            history: history
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let snapshot = try JSONDecoder().decode(LibrarySnapshot.self, from: data)
            guard snapshot.schemaVersion == 1 else {
                throw LibraryStoreError.unsupportedSchema(snapshot.schemaVersion)
            }
            books = snapshot.books
            history = snapshot.history
        } catch {
            errorMessage = "无法读取资料库：\(error.localizedDescription)"
        }
    }

    private static func defaultStorageURL() -> URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
        return applicationSupport
            .appendingPathComponent("AudioShelf", isDirectory: true)
            .appendingPathComponent("library.json")
    }
}

private enum LibraryStoreError: LocalizedError {
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            return "不支持的资料库版本：\(version)。"
        }
    }
}
