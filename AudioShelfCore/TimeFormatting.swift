import Foundation

public enum TimeFormatting {
    public static func playbackTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let remainingSeconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    public static func durationDescription(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "时长未知" }
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 {
            return "\(max(minutes, 1)) 分钟"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours) 小时" : "\(hours) 小时 \(remainingMinutes) 分钟"
    }
}
