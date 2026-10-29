import Foundation

/// Controls the lifetime of one upload run inside a `beginBackgroundTask`.
///
/// The guard ends the background task exactly once, and when the task
/// expires it cancels the request in flight, ends the task right away, and
/// stops the run from starting another request. It's thread-safe.
public final class UploadRunGuard {
    private let lock = NSLock()
    private let endBackgroundTask: () -> Void
    private var ended = false
    private var expired = false
    private var cancelCurrent: (() -> Void)?

    /// Creates a guard that calls `endBackgroundTask` at most once.
    public init(endBackgroundTask: @escaping () -> Void) {
        self.endBackgroundTask = endBackgroundTask
    }

    /// Whether the background task expired.
    public var isExpired: Bool {
        lock.lock(); defer { lock.unlock() }
        return expired
    }

    /// Registers the request that's about to start. Returns `false` if the
    /// run already expired; don't start the request then.
    public func begin(cancel: @escaping () -> Void) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !expired else { return false }
        cancelCurrent = cancel
        return true
    }

    /// Call from the background task's expiration handler. Cancels the
    /// request in flight and ends the background task before returning, as
    /// iOS requires; the request's completion then finds the run expired.
    public func expire() {
        lock.lock()
        // After a normal finish there's nothing left to cancel or end.
        let cancel = ended ? nil : cancelCurrent
        if !ended { expired = true }
        cancelCurrent = nil
        lock.unlock()
        cancel?()
        finish()
    }

    /// Ends the background task when the run is done. Later calls do nothing.
    public func finish() {
        lock.lock()
        let shouldEnd = !ended
        ended = true
        cancelCurrent = nil
        lock.unlock()
        if shouldEnd { endBackgroundTask() }
    }
}
