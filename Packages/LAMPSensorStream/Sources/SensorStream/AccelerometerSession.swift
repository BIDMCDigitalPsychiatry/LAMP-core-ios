import Foundation

/// One accelerometer sample as CoreMotion delivers it, with the clock
/// readings taken when the handler received it.
public struct MotionSample: Equatable {
    /// `CMLogItem.timestamp`: seconds since boot when the sample was taken.
    public let uptime: Double
    /// Acceleration in g, iOS axes.
    public let xG: Double
    public let yG: Double
    public let zG: Double
    /// The wall clock, in epoch seconds, when the handler received the sample.
    public let receivedWallEpochSeconds: Double
    /// The uptime, in seconds since boot, when the handler received the sample.
    public let receivedUptimeSeconds: Double

    public init(uptime: Double, xG: Double, yG: Double, zG: Double,
                receivedWallEpochSeconds: Double, receivedUptimeSeconds: Double) {
        self.uptime = uptime
        self.xG = xG
        self.yG = yG
        self.zG = zG
        self.receivedWallEpochSeconds = receivedWallEpochSeconds
        self.receivedUptimeSeconds = receivedUptimeSeconds
    }
}

/// Converts drained CoreMotion samples to records with one clock session at a
/// time and hands them to a `FrameRecorder`.
///
/// Call it from one serial queue.
public final class AccelerometerSession {
    public let recorder: FrameRecorder
    public private(set) var clock = SensorClock()

    public init(recorder: FrameRecorder) {
        self.recorder = recorder
    }

    /// Starts the first clock session.
    @discardableResult
    public func start(wallEpochSeconds: Double, uptimeSeconds: Double) throws -> [SealedFrame] {
        clock.startSession(wallEpochSeconds: wallEpochSeconds, uptimeSeconds: uptimeSeconds)
        return []
    }

    /// Converts and records one drained batch. Returns the frames it sealed.
    ///
    /// The drift check runs at each sample's arrival, so samples received
    /// before a clock change or a deep sleep keep their own session's offset.
    /// When the drift exceeds `SensorClock.maxDriftMs`, the samples so far are
    /// recorded, the open frame closes, and a new session starts.
    @discardableResult
    public func drain(_ samples: [MotionSample], wallEpochSeconds: Double, uptimeSeconds: Double) throws -> [SealedFrame] {
        let nowMs = Self.milliseconds(wallEpochSeconds)
        var sealed: [SealedFrame] = []
        var records: [AccelRecord] = []
        records.reserveCapacity(samples.count)
        for sample in samples {
            if clock.restartIfDrifted(wallEpochSeconds: sample.receivedWallEpochSeconds,
                                      uptimeSeconds: sample.receivedUptimeSeconds) {
                sealed += try endSession(records, nowMs: nowMs)
                records.removeAll(keepingCapacity: true)
            }
            if let timestamp = clock.epochMs(uptimeSeconds: sample.uptime) {
                records.append(UnitConversion.record(timestamp: timestamp, xG: sample.xG, yG: sample.yG, zG: sample.zG))
            }
        }
        // The clock can also move after the last sample (for example, a sleep with no samples since).
        if clock.restartIfDrifted(wallEpochSeconds: wallEpochSeconds, uptimeSeconds: uptimeSeconds) {
            sealed += try endSession(records, nowMs: nowMs)
            records.removeAll()
        }
        sealed += try recorder.ingest(records, nowMs: nowMs)
        return sealed
    }

    /// Records the last batch and seals the open frame (collector stop).
    @discardableResult
    public func stop(_ samples: [MotionSample], wallEpochSeconds: Double, uptimeSeconds: Double) throws -> [SealedFrame] {
        let sealed = try drain(samples, wallEpochSeconds: wallEpochSeconds, uptimeSeconds: uptimeSeconds)
        return try sealed + recorder.closeOpenFrame()
    }

    /// Records the old session's last records, then closes its open frame.
    private func endSession(_ records: [AccelRecord], nowMs: Int64) throws -> [SealedFrame] {
        try recorder.ingest(records, nowMs: nowMs) + recorder.startNewSession()
    }

    private static func milliseconds(_ seconds: Double) -> Int64 {
        Int64((seconds * 1_000).rounded(.down))
    }
}
