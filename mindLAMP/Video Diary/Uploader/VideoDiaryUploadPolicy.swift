// mindLAMP
//
// Controls constraints such as whether uploads may use cellular data.

import Foundation

/// Policy chosen when enqueueing a recording for upload (persisted on the job for deterministic retries).
struct VideoDiaryUploadPolicy: Codable, Equatable, Sendable {
    /// When `false`, uploads wait until an unmetered Wi‑Fi (or suitable Ethernet) path is available.
    var allowsCellularUpload: Bool

    init(allowsCellularUpload: Bool) {
        self.allowsCellularUpload = allowsCellularUpload
    }

    /// Cellular and Wi‑Fi uploads are allowed (typical default).
    static let `default` = VideoDiaryUploadPolicy(allowsCellularUpload: true)

    /// Only Wi‑Fi / unmetered paths (uses `NWPathMonitor` interpretation in the coordinator).
    static let wifiOnly = VideoDiaryUploadPolicy(allowsCellularUpload: false)
}
