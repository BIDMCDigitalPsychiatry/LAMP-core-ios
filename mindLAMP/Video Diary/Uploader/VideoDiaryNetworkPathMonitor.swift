// mindLAMP
//
// Abstract path monitoring for Wi‑Fi-only uploads (`NWPathMonitor`).

import Foundation
#if canImport(Network)
import Network
#endif

/// Describes whether the current path satisfies a [`VideoDiaryUploadPolicy`](VideoDiaryUploadPolicy.swift).
protocol VideoDiaryNetworkPathMonitoring: AnyObject, Sendable {
    /// Called on any significant path change (queue coordinator resumes waiting uploads).
    var onPathsMayHaveChanged: (@Sendable () -> Void)? { get set }

    func start()
    func stop()
    /// Returns `true` when uploading is allowed under the given policy **right now**.
    func allowsUpload(with policy: VideoDiaryUploadPolicy) -> Bool
}

#if canImport(Network)

/// Production implementation using `NWPathMonitor`.
final class VideoDiarySystemNetworkPathMonitor: VideoDiaryNetworkPathMonitoring, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var lastPath: NWPath?
    var onPathsMayHaveChanged: (@Sendable () -> Void)?

    init(
        monitor: NWPathMonitor = NWPathMonitor(),
        queue: DispatchQueue = DispatchQueue(label: "VideoDiarySystemNetworkPathMonitor", qos: .utility)
    ) {
        self.monitor = monitor
        self.queue = queue
    }

    func start() {
        lastPath = monitor.currentPath
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.lastPath = path
            self.onPathsMayHaveChanged?()
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }

    func allowsUpload(with policy: VideoDiaryUploadPolicy) -> Bool {
        let path = lastPath ?? monitor.currentPath
        return Self.evaluate(path: path, policy: policy)
    }

    /// Unsatisfied: no route. Expensive + cellular disallowed: wait. Otherwise allow.
    static func evaluate(path: NWPath, policy: VideoDiaryUploadPolicy) -> Bool {
        guard path.status == .satisfied else { return false }
        if policy.allowsCellularUpload { return true }
        if path.usesInterfaceType(.wifi) { return true }
        if path.usesInterfaceType(.wiredEthernet) { return true }
        // Other interface types (cellular) are blocked when only Wi‑Fi is allowed.
        return false
    }
}

#else

/// Fallback when `Network` is unavailable (e.g. some test environments): always allow.
final class VideoDiarySystemNetworkPathMonitor: VideoDiaryNetworkPathMonitoring, @unchecked Sendable {
    var onPathsMayHaveChanged: (@Sendable () -> Void)?

    init() {}

    func start() {}

    func stop() {}

    func allowsUpload(with policy: VideoDiaryUploadPolicy) -> Bool { true }
}

#endif
