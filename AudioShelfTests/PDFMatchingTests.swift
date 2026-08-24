import Testing
#if SWIFT_PACKAGE
@testable import AudioShelfCore
#else
@testable import AudioShelf
#endif

@Test("PDF 文件名忽略大小写、空格和标点")
func pdfNameIgnoresFormattingDifferences() {
    #expect(PDFMatching.matches(pdfFileName: "The-Hobbit.pdf", candidateNames: ["the hobbit"]))
}

@Test("PDF 文件名支持中文同名")
func pdfNameMatchesChineseBookTitle() {
    #expect(PDFMatching.matches(pdfFileName: "三体.pdf", candidateNames: ["三体"]))
}

@Test("不同编号的书不会错误匹配")
func differentBookNumberDoesNotMatch() {
    #expect(!PDFMatching.matches(pdfFileName: "三体2.pdf", candidateNames: ["三体"]))
}
