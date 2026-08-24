import AVFoundation
import Combine
import Foundation

@MainActor
final class PlayerController: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var hasLoadedChapter = false
    @Published private(set) var currentTime = 0.0
    @Published private(set) var duration = 0.0
    @Published private(set) var currentBookID: UUID?
    @Published private(set) var currentChapterID: UUID?
    @Published private(set) var currentBookTitle = ""
    @Published private(set) var currentChapterTitle = ""
    @Published private(set) var sleepTimerDescription: String?
    @Published var errorMessage: String?
    @Published var playbackRate: Float = 1.0 {
        didSet {
            player.defaultRate = playbackRate
            if isPlaying {
                player.rate = playbackRate
            }
        }
    }

    let availableRates: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var failedObserver: NSObjectProtocol?
    private var libraryStore: LibraryStore?
    private var loadedBook: Audiobook?
    private var loadedChapter: Chapter?
    private var activeRecord: PlaybackRecord?
    private var accessedScopeURL: URL?
    private var didStartScopeAccess = false
    private var lastPersistedTime = -1.0
    private var sleepDeadline: Date?
    private var pauseAtChapterEnd = false

    init() {
        player.defaultRate = playbackRate
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.handlePeriodicTime(time.seconds)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self,
                      let item = notification.object as? AVPlayerItem,
                      item === self.player.currentItem else { return }
                self.handleChapterEnded()
            }
        }

        failedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let self,
                      let item = notification.object as? AVPlayerItem,
                      item === self.player.currentItem else { return }
                self.isPlaying = false
                self.persistProgress(force: true)
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self.errorMessage = error?.localizedDescription ?? "音频播放失败。"
            }
        }
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let failedObserver {
            NotificationCenter.default.removeObserver(failedObserver)
        }
        if didStartScopeAccess {
            accessedScopeURL?.stopAccessingSecurityScopedResource()
        }
    }

    func load(
        book: Audiobook,
        chapter: Chapter,
        store: LibraryStore,
        autoPlay: Bool = true,
        resumeSavedPosition: Bool = false
    ) {
        let requestedSavedPosition = resumeSavedPosition && book.lastChapterID == chapter.id
            ? book.playbackPosition
            : 0

        if currentBookID == book.id, currentChapterID == chapter.id, hasLoadedChapter {
            if requestedSavedPosition > 0, abs(currentTime - requestedSavedPosition) > 1 {
                seek(to: requestedSavedPosition)
            }
            if autoPlay { play() }
            return
        }

        persistProgress(force: true)
        closeActiveRecord(completed: false)
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        releaseSecurityScope()

        do {
            let resource = try BookmarkService.resolve(chapter: chapter, in: book)
            accessedScopeURL = resource.scopeURL
            didStartScopeAccess = resource.scopeURL.startAccessingSecurityScopedResource()

            libraryStore = store
            loadedBook = book
            loadedChapter = chapter
            currentBookID = book.id
            currentChapterID = chapter.id
            currentBookTitle = book.title
            currentChapterTitle = chapter.title
            duration = chapter.duration
            currentTime = min(max(requestedSavedPosition, 0), max(chapter.duration, 0))
            lastPersistedTime = -1
            hasLoadedChapter = true
            isPlaying = false

            let item = AVPlayerItem(url: resource.audioURL)
            player.replaceCurrentItem(with: item)
            player.defaultRate = playbackRate
            player.seek(
                to: CMTime(seconds: currentTime, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )

            book.lastChapterID = chapter.id
            book.lastPlayedAt = Date()
            book.completedAt = nil
            createPlaybackRecord(book: book, chapter: chapter, startPosition: currentTime)
            try store.save()

            if autoPlay {
                play()
            }
        } catch {
            player.replaceCurrentItem(with: nil)
            releaseSecurityScope()
            resetLoadedState()
            errorMessage = error.localizedDescription
        }
    }

    func continueBook(_ book: Audiobook, store: LibraryStore) {
        guard let chapter = book.currentChapter else { return }
        load(
            book: book,
            chapter: chapter,
            store: store,
            autoPlay: true,
            resumeSavedPosition: true
        )
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard hasLoadedChapter, player.currentItem != nil else { return }
        loadedBook?.lastPlayedAt = Date()
        player.playImmediately(atRate: playbackRate)
        isPlaying = true
        persistProgress(force: true)
    }

    func pause() {
        player.pause()
        isPlaying = false
        persistProgress(force: true)
    }

    func seek(to seconds: Double) {
        guard hasLoadedChapter else { return }
        let upperBound = duration > 0 ? duration : max(seconds, 0)
        let target = min(max(seconds, 0), upperBound)
        currentTime = target
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: CMTime(seconds: 0.1, preferredTimescale: 600),
            toleranceAfter: CMTime(seconds: 0.1, preferredTimescale: 600)
        )
        persistProgress(force: true)
    }

    func skip(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    func previousChapter() {
        guard let book = loadedBook,
              let chapter = loadedChapter,
              let store = libraryStore else { return }
        let chapters = book.sortedChapters
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        if index == chapters.startIndex {
            seek(to: 0)
            return
        }
        load(book: book, chapter: chapters[index - 1], store: store, autoPlay: true)
    }

    func nextChapter() {
        guard let book = loadedBook,
              let chapter = loadedChapter,
              let store = libraryStore else { return }
        let chapters = book.sortedChapters
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }),
              chapters.indices.contains(index + 1) else {
            pause()
            return
        }
        load(book: book, chapter: chapters[index + 1], store: store, autoPlay: true)
    }

    func setSleepTimer(minutes: Int) {
        sleepDeadline = Date().addingTimeInterval(TimeInterval(minutes * 60))
        pauseAtChapterEnd = false
        sleepTimerDescription = "\(minutes) 分钟后"
    }

    func setSleepAtChapterEnd() {
        sleepDeadline = nil
        pauseAtChapterEnd = true
        sleepTimerDescription = "本章结束"
    }

    func cancelSleepTimer() {
        sleepDeadline = nil
        pauseAtChapterEnd = false
        sleepTimerDescription = nil
    }

    func persistProgress(force: Bool) {
        guard let book = loadedBook,
              let chapter = loadedChapter,
              let store = libraryStore else { return }
        if !force, abs(currentTime - lastPersistedTime) < 5 { return }

        book.lastChapterID = chapter.id
        book.playbackPosition = min(max(currentTime, 0), duration > 0 ? duration : currentTime)
        activeRecord?.endPosition = book.playbackPosition
        activeRecord?.updatedAt = Date()
        do {
            try store.save()
            lastPersistedTime = currentTime
        } catch {
            if force {
                errorMessage = "无法保存播放位置：\(error.localizedDescription)"
            }
        }
    }

    func stopIfPlaying(bookID: UUID) {
        guard currentBookID == bookID else { return }
        pause()
        closeActiveRecord(completed: false)
        player.replaceCurrentItem(with: nil)
        releaseSecurityScope()
        resetLoadedState()
    }

    private func handlePeriodicTime(_ seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else { return }
        currentTime = seconds
        if let itemDuration = player.currentItem?.duration.seconds,
           itemDuration.isFinite,
           itemDuration > 0 {
            duration = itemDuration
            loadedChapter?.duration = itemDuration
            if let book = loadedBook {
                let refreshedTotal = book.chapters.reduce(0) { $0 + $1.duration }
                if abs(book.totalDuration - refreshedTotal) > 0.5 {
                    book.totalDuration = refreshedTotal
                }
            }
        }
        persistProgress(force: false)

        if let deadline = sleepDeadline, Date() >= deadline {
            pause()
            cancelSleepTimer()
        }
    }

    private func handleChapterEnded() {
        currentTime = duration
        activeRecord?.completed = true
        persistProgress(force: true)
        closeActiveRecord(completed: true)

        if pauseAtChapterEnd {
            player.pause()
            isPlaying = false
            cancelSleepTimer()
            return
        }

        guard let book = loadedBook,
              let chapter = loadedChapter else { return }
        let chapters = book.sortedChapters
        if let index = chapters.firstIndex(where: { $0.id == chapter.id }),
           chapters.indices.contains(index + 1) {
            nextChapter()
        } else {
            book.completedAt = Date()
            player.pause()
            isPlaying = false
            try? libraryStore?.save()
        }
    }

    private func createPlaybackRecord(book: Audiobook, chapter: Chapter, startPosition: Double) {
        guard let store = libraryStore else { return }
        let record = PlaybackRecord(
            bookID: book.id,
            chapterID: chapter.id,
            bookTitle: book.title,
            chapterTitle: chapter.title,
            startPosition: startPosition,
            endPosition: startPosition
        )
        store.appendHistory(record)
        activeRecord = record
    }

    private func closeActiveRecord(completed: Bool) {
        guard let record = activeRecord else { return }
        record.endPosition = currentTime
        record.updatedAt = Date()
        record.completed = record.completed || completed
        try? libraryStore?.save()
        activeRecord = nil
    }

    private func releaseSecurityScope() {
        if didStartScopeAccess {
            accessedScopeURL?.stopAccessingSecurityScopedResource()
        }
        accessedScopeURL = nil
        didStartScopeAccess = false
    }

    private func resetLoadedState() {
        loadedBook = nil
        loadedChapter = nil
        libraryStore = nil
        activeRecord = nil
        currentBookID = nil
        currentChapterID = nil
        currentBookTitle = ""
        currentChapterTitle = ""
        currentTime = 0
        duration = 0
        hasLoadedChapter = false
        isPlaying = false
        lastPersistedTime = -1
        sleepDeadline = nil
        pauseAtChapterEnd = false
        sleepTimerDescription = nil
    }
}
