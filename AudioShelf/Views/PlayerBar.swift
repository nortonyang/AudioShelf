import SwiftUI
#if SWIFT_PACKAGE
import AudioShelfCore
#endif

struct PlayerBar: View {
    @EnvironmentObject private var player: PlayerController
    @State private var scrubValue = 0.0
    @State private var isScrubbing = false

    var body: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentBookTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Text(player.currentChapterTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 190, alignment: .leading)

                Button {
                    player.skip(by: -15)
                } label: {
                    Image(systemName: "gobackward.15")
                }
                .help("快退 15 秒")

                Button {
                    player.previousChapter()
                } label: {
                    Image(systemName: "backward.end.fill")
                }
                .help("上一章")

                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .help(player.isPlaying ? "暂停" : "播放")

                Button {
                    player.nextChapter()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
                .help("下一章")

                Button {
                    player.skip(by: 30)
                } label: {
                    Image(systemName: "goforward.30")
                }
                .help("快进 30 秒")

                VStack(spacing: 2) {
                    Slider(
                        value: $scrubValue,
                        in: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            isScrubbing = editing
                            if !editing {
                                player.seek(to: scrubValue)
                            }
                        }
                    )
                    HStack {
                        Text(TimeFormatting.playbackTime(scrubValue))
                        Spacer()
                        Text("-\(TimeFormatting.playbackTime(max(player.duration - scrubValue, 0)))")
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                .frame(minWidth: 180, maxWidth: .infinity)

                Menu {
                    ForEach(player.availableRates, id: \.self) { rate in
                        Button {
                            player.playbackRate = rate
                        } label: {
                            if player.playbackRate == rate {
                                Label(rateLabel(rate), systemImage: "checkmark")
                            } else {
                                Text(rateLabel(rate))
                            }
                        }
                    }
                } label: {
                    Text(rateLabel(player.playbackRate))
                        .monospacedDigit()
                        .frame(minWidth: 38)
                }
                .help("播放速度")

                Menu {
                    Button("15 分钟") { player.setSleepTimer(minutes: 15) }
                    Button("30 分钟") { player.setSleepTimer(minutes: 30) }
                    Button("60 分钟") { player.setSleepTimer(minutes: 60) }
                    Button("本章结束") { player.setSleepAtChapterEnd() }
                    if player.sleepTimerDescription != nil {
                        Divider()
                        Button("关闭定时") { player.cancelSleepTimer() }
                    }
                } label: {
                    Image(systemName: player.sleepTimerDescription == nil ? "moon.zzz" : "moon.zzz.fill")
                }
                .help(player.sleepTimerDescription.map { "睡眠定时：\($0)" } ?? "睡眠定时")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .background(.regularMaterial)
        .onAppear {
            scrubValue = player.currentTime
        }
        .onChange(of: player.currentTime) { _, newValue in
            if !isScrubbing {
                scrubValue = newValue
            }
        }
    }

    private func rateLabel(_ rate: Float) -> String {
        rate == rate.rounded() ? String(format: "%.0f×", rate) : String(format: "%.2g×", rate)
    }
}
