import Foundation

public enum PDFMatching {
    public static func normalizedName(_ value: String) -> String {
        var name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let pathExtension = (name as NSString).pathExtension.lowercased()
        if pathExtension == "pdf" || pathExtension == "mp3" {
            name = (name as NSString).deletingPathExtension
        }

        let folded = name.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: .current
        ).lowercased()
        let scalars = folded.unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    public static func matches(pdfFileName: String, candidateNames: [String]) -> Bool {
        let pdfName = normalizedName(pdfFileName)
        guard !pdfName.isEmpty else { return false }
        return candidateNames.contains { normalizedName($0) == pdfName }
    }
}
