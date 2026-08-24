import SwiftUI
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

struct HistoryListView: View {
    let records: [PlaybackRecord]
    let onOpenBook: (UUID) -> Void

    var body: some View {
        if records.isEmpty {
            ContentUnavailableView(
                "暂无播放历史",
                systemImage: "clock.arrow.circlepath",
                description: Text("开始播放有声书后，章节记录会显示在这里。")
            )
        } else {
            List(records) { record in
                Button {
                    onOpenBook(record.bookID)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(record.bookTitle)
                                .font(.headline)
                                .lineLimit(1)
                            Spacer()
                            if record.completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .accessibilityLabel("已完成章节")
                            }
                        }
                        Text(record.chapterTitle)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        HStack {
                            Text(record.startedAt, format: .relative(presentation: .named))
                            Spacer()
                            Text("\(TimeFormatting.playbackTime(record.startPosition)) → \(TimeFormatting.playbackTime(record.endPosition))")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
    }
}
