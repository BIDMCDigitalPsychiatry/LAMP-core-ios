// mindLAMP
//
// Wires `AppDelegate.handleEventsForBackgroundURLSession` to the system completion handler. When a background
// `URLSession` is introduced for S3 part uploads, finish work here then call the stored handler.

import Foundation

/// Retains the background session completion handler until all reconnections are done.
final class VideoDiaryURLSessionBackgroundCompletionRegistry: @unchecked Sendable {
    static let shared = VideoDiaryURLSessionBackgroundCompletionRegistry()

    /// Serializes handler registration vs drain; a concurrent queue + barrier would also work, but a single serial queue is simpler here.
    private let isolationQueue = DispatchQueue(
        label: "digital.lamp.VideoDiaryURLSessionBackgroundCompletionRegistry",
        qos: .utility
    )
    private var pendingCompletions: [() -> Void] = []

    private init() {}

    func setBackgroundSessionCompletionHandler(_ handler: @escaping () -> Void) {
        isolationQueue.sync {
            pendingCompletions.append(handler)
        }
    }

    /// Call when the app has reattached to all background URL sessions and finished handling events.
    func signalAllEventsProcessed() {
        let handlers = isolationQueue.sync { () -> [() -> Void] in
            let copy = pendingCompletions
            pendingCompletions.removeAll()
            return copy
        }
        handlers.forEach { $0() }
    }
}
