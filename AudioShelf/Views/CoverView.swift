import AppKit
import SwiftUI

struct CoverView: View {
    let title: String
    let artworkData: Data?

    var body: some View {
        Group {
            if let artworkData,
               let image = NSImage(data: artworkData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.95), Color.blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 36, weight: .semibold))
                        Text(monogram)
                            .font(.title2.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding()
                }
            }
        }
        .clipped()
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .accessibilityLabel("《\(title)》封面")
    }

    private var monogram: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.first.map(String.init) ?? "声"
    }
}
