import AVFoundation
import Foundation

struct AudioMetadata {
    var title: String?
    var album: String?
    var artist: String?
    var artworkData: Data?
    var duration: Double
}

enum MetadataService {
    static func read(from url: URL) async throws -> AudioMetadata {
        let asset = AVURLAsset(url: url)
        async let loadedDuration = asset.load(.duration)
        let items = try await asset.load(.commonMetadata)

        var metadata = AudioMetadata(duration: 0)
        for item in items {
            switch item.commonKey?.rawValue {
            case AVMetadataKey.commonKeyTitle.rawValue:
                metadata.title = try? await item.load(.stringValue)
            case AVMetadataKey.commonKeyAlbumName.rawValue:
                metadata.album = try? await item.load(.stringValue)
            case AVMetadataKey.commonKeyArtist.rawValue:
                metadata.artist = try? await item.load(.stringValue)
            case AVMetadataKey.commonKeyArtwork.rawValue:
                metadata.artworkData = try? await item.load(.dataValue)
            default:
                continue
            }
        }

        let seconds = try await loadedDuration.seconds
        metadata.duration = seconds.isFinite && seconds > 0 ? seconds : 0
        return metadata
    }
}
