import Foundation

/// What the uploader does with a frame after a response.
public enum UploadAction: Equatable {
    /// Stored (or already stored): delete the local frame.
    case delete
    /// Rejected for good: move the frame to quarantine and don't retry.
    case quarantine
    /// Not authenticated: keep the frame and retry after the session is refreshed.
    case retryAfterAuthRefresh
    /// Transient failure: keep the frame and retry with exponential backoff.
    case retryWithBackoff
}

/// Maps upload responses to client actions (contract table "Responses and client actions").
public enum UploadPolicy {
    /// The largest frame the server accepts, in bytes (4 MiB).
    public static let maxFrameBytes = 4_194_304
    /// The first retry delay, in seconds.
    public static let baseBackoff: TimeInterval = 30
    /// The longest retry delay, in seconds.
    public static let maxBackoff: TimeInterval = 3_600

    /// Returns the action for an HTTP status code, or for a network error when `statusCode` is `nil`.
    public static func action(forStatusCode statusCode: Int?) -> UploadAction {
        .delete
    }

    /// Returns the delay before the next attempt after `failures` consecutive failures.
    public static func backoffDelay(afterFailures failures: Int) -> TimeInterval {
        0
    }
}

/// The body of a `200` upload response: `{"data": {"id": "...", "duplicate": true}}`.
public struct SensorStreamUploadResponse: Decodable, Equatable {
    public struct Payload: Decodable, Equatable {
        public let id: String
        public let duplicate: Bool?
    }
    public let data: Payload
}
