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

/// Everything the uploader does after one response.
public struct UploadStep: Equatable {
    /// What happens to the frame.
    public let action: UploadAction
    /// Refresh the access token so the next run can retry.
    public let refreshesSession: Bool
    /// Count a failure and wait `UploadPolicy.backoffDelay(afterFailures:)` before the next run.
    public let backsOff: Bool
    /// Upload the next frame in this run.
    public let continuesRun: Bool

    public init(action: UploadAction, refreshesSession: Bool, backsOff: Bool, continuesRun: Bool) {
        self.action = action
        self.refreshesSession = refreshesSession
        self.backsOff = backsOff
        self.continuesRun = continuesRun
    }
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
    ///
    /// Codes that the contract doesn't list keep the frame for a later retry,
    /// so an unexpected response never loses data.
    public static func action(forStatusCode statusCode: Int?) -> UploadAction {
        switch statusCode {
        case .some(200...299):
            return .delete
        case .some(400), .some(409), .some(413):
            return .quarantine
        case .some(401), .some(403):
            return .retryAfterAuthRefresh
        default:
            return .retryWithBackoff
        }
    }

    /// Returns the uploader's full response to an HTTP status code, or to a
    /// network error when `statusCode` is `nil`.
    public static func step(forStatusCode statusCode: Int?) -> UploadStep {
        let action = action(forStatusCode: statusCode)
        return UploadStep(action: action,
                          // The server answers 403, not 401, for an expired mobile token, so both refresh.
                          refreshesSession: action == .retryAfterAuthRefresh,
                          // Back off on auth failures too, so a run doesn't re-hit the server every cycle.
                          backsOff: action == .retryAfterAuthRefresh || action == .retryWithBackoff,
                          continuesRun: action == .delete || action == .quarantine)
    }

    /// Returns the delay before the next attempt after `failures` consecutive failures.
    public static func backoffDelay(afterFailures failures: Int) -> TimeInterval {
        guard failures > 0 else { return 0 }
        // 30 s doubled per failure; the exponent is capped so the power can't overflow.
        let delay = baseBackoff * pow(2, Double(min(failures - 1, 16)))
        return min(delay, maxBackoff)
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
