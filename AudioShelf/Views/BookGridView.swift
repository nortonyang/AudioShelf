import SwiftUI
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

struct BookGridView: View {
    let books: [Audiobook]
    @Binding var selectedBookID: UUID?
    let onPlay: (Audiobook) -> Void
    let onDelete: (Audiobook) -> Void

    @State private var hoveredBookID: UUID?

    private let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 210), spacing: 18, alignment: .top)
    ]

    var body: some View {
        if books.isEmpty {
            ContentUnavailableView(
                "没有匹配的有声书",
                systemImage: "books.vertical",
                description: Text("导入 MP3 或文件夹，或尝试其他搜索词。")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    ForEach(books) { book in
                        bookCard(book)
                    }
                }
                .padding(20)
            }
        }
    }

    private func bookCard(_ book: Audiobook) -> some View {
        let isSelected = selectedBookID == book.id
        let isHovered = hoveredBookID == book.id

        return VStack(alignment: .leading, spacing: 10) {
            CoverView(title: book.title, artworkData: book.coverData)
                .aspectRatio(1, contentMode: .fit)

            Text(book.title)
                .font(.headline.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)
                .frame(minHeight: 40, alignment: .topLeading)

            Text(book.author ?? "未知作者")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                Label("\(book.chapters.count) 章", systemImage: "list.number")
                Text("·")
                Text(TimeFormatting.durationDescription(book.totalDuration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            VStack(spacing: 5) {
                HStack {
                    Text(book.overallProgress > 0 ? "收听进度" : "尚未开始")
                    Spacer()
                    if book.overallProgress > 0 {
                        Text("\(Int((book.overallProgress * 100).rounded()))%")
                            .monospacedDigit()
                    }
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

                ProgressView(value: book.overallProgress)
                    .progressViewStyle(.linear)
                    .opacity(book.overallProgress > 0 ? 1 : 0.35)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.13)
                        : Color.primary.opacity(isHovered ? 0.07 : 0.035)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.8) : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        }
        .shadow(color: .black.opacity(isHovered ? 0.14 : 0.06), radius: isHovered ? 10 : 4, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            selectedBookID = book.id
        }
        .onTapGesture(count: 2) {
            selectedBookID = book.id
            onPlay(book)
        }
        .onHover { hovering in
            hoveredBookID = hovering ? book.id : nil
        }
        .animation(.easeOut(duration: 0.16), value: isHovered)
        .animation(.easeOut(duration: 0.16), value: isSelected)
        .contextMenu {
            Button {
                onPlay(book)
            } label: {
                Label(book.overallProgress > 0 ? "继续播放" : "开始播放", systemImage: "play.fill")
            }
            Divider()
            Button(role: .destructive) {
                onDelete(book)
            } label: {
                Label("从资料库移除", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(book.title)，\(book.author ?? "未知作者")，\(book.chapters.count) 章，\(TimeFormatting.durationDescription(book.totalDuration))"
        )
        .accessibilityValue(
            book.overallProgress > 0
                ? "已播放 \(Int((book.overallProgress * 100).rounded()))%"
                : "尚未开始"
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: "播放") { onPlay(book) }
    }
}
