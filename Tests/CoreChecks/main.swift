import AudioShelfCore
import Foundation

private func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("检查失败：\(message)\n".utf8))
        exit(1)
    }
}

check(
    NaturalSort.sorted(["第10章", "第2章", "第1章"]) == ["第1章", "第2章", "第10章"],
    "中文数字章节自然排序"
)
check(
    NaturalSort.sorted(["track 11.mp3", "track 2.mp3", "track 1.mp3"])
        == ["track 1.mp3", "track 2.mp3", "track 11.mp3"],
    "英文数字文件名自然排序"
)
check(TimeFormatting.playbackTime(65) == "1:05", "分钟时间格式")
check(TimeFormatting.playbackTime(3_661) == "1:01:01", "小时时间格式")
check(TimeFormatting.durationDescription(3_900) == "1 小时 5 分钟", "时长描述")
check(
    PDFMatching.matches(pdfFileName: "The-Hobbit.pdf", candidateNames: ["the hobbit"]),
    "PDF 英文名称规范化"
)
check(
    PDFMatching.matches(pdfFileName: "三体.pdf", candidateNames: ["三体"]),
    "PDF 中文同名匹配"
)
check(
    !PDFMatching.matches(pdfFileName: "三体2.pdf", candidateNames: ["三体"]),
    "PDF 不同编号不匹配"
)

print("AudioShelfCoreChecks：全部通过")
