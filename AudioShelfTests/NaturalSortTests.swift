import Testing
#if SWIFT_PACKAGE
@testable import AudioShelfCore
#else
@testable import AudioShelf
#endif

@Test("数字章节名使用 Finder 风格自然排序")
func numericChapterNamesUseFinderStyleOrdering() {
    let input = ["第10章", "第2章", "第1章"]
    #expect(NaturalSort.sorted(input) == ["第1章", "第2章", "第10章"])
}

@Test("文件名使用 Finder 风格自然排序")
func fileNamesUseFinderStyleOrdering() {
    let input = ["track 11.mp3", "track 2.mp3", "track 1.mp3"]
    #expect(NaturalSort.sorted(input) == ["track 1.mp3", "track 2.mp3", "track 11.mp3"])
}

@Test("本地化相同值仍保留全部元素")
func equalLocalizedValuesHaveStableTieBreaker() {
    let input = ["A", "a"]
    #expect(NaturalSort.sorted(input).count == 2)
}

@Test("播放时间格式")
func playbackTimeFormatting() {
    #expect(TimeFormatting.playbackTime(65) == "1:05")
    #expect(TimeFormatting.playbackTime(3_661) == "1:01:01")
}
