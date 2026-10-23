//  mindLAMP Consortium

#if os(iOS)
import CoreMotion
import Foundation
import SensorStream

/// Records one accelerometer tier (`lamp.accelerometer{10,20,50,100}hz`) into
/// sensor-stream frames under `Documents/SensorStream`.
///
/// CoreMotion pushes samples into an in-memory buffer; every
/// `SensorTier.drainInterval` (5 s) the buffer is converted to records
/// (epoch ms, m/s², Android axes) and handed to a `FrameRecorder`, which
/// appends the open frame to disk and seals closed frames for upload. In the
/// background, updates keep arriving only while the app's continuous location
/// updates keep it running.
final class HighRateAccelerometer {

    /// The app's only `CMMotionManager` for sensor-stream tiers. Apple recommends
    /// one instance per app; only one tier runs at a time.
    static let motionManager = CMMotionManager()

    private struct Sample {
        let uptime: TimeInterval
        let x: Double
        let y: Double
        let z: Double
    }

    let tier: SensorTier
    private let store: FrameStore
    private let recorder: FrameRecorder
    /// Serializes the clock, the recorder, and the store.
    private let queue = DispatchQueue(label: "digital.lamp.sensorstream.accelerometer", qos: .utility)
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "digital.lamp.sensorstream.motion"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private let bufferLock = NSLock()
    private var buffer: [Sample] = []
    private var clock = SensorClock()
    private var drainTimer: DispatchSourceTimer?
    private(set) var isRunning = false

    init(tier: SensorTier, store: FrameStore) {
        self.tier = tier
        self.store = store
        self.recorder = FrameRecorder(spec: tier.spec, store: store)
    }

    /// Seals frames left open by an earlier run, then starts sampling.
    func start() {
        let manager = Self.motionManager
        guard !isRunning, manager.isAccelerometerAvailable else { return }
        isRunning = true
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.store.recoverOpenFrames()
            } catch {
                printToFile("sensor-stream recovery failed: \(error)")
            }
            self.clock.startSession(wallEpochSeconds: Date().timeIntervalSince1970,
                                    uptimeSeconds: ProcessInfo.processInfo.systemUptime)
        }
        bufferLock.lock()
        buffer.reserveCapacity(tier.nominalHz * Int(SensorTier.drainInterval) * 2)
        bufferLock.unlock()

        manager.accelerometerUpdateInterval = tier.accelerometerUpdateInterval
        manager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let sample = Sample(uptime: data.timestamp, x: data.acceleration.x,
                                y: data.acceleration.y, z: data.acceleration.z)
            self.bufferLock.lock()
            self.buffer.append(sample)
            self.bufferLock.unlock()
        }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + SensorTier.drainInterval, repeating: SensorTier.drainInterval)
        timer.setEventHandler { [weak self] in self?.drain() }
        timer.resume()
        drainTimer = timer
    }

    /// Stops sampling, drains the buffer, and seals the open frame.
    func stop() {
        guard isRunning else { return }
        isRunning = false
        Self.motionManager.stopAccelerometerUpdates()
        drainTimer?.cancel()
        drainTimer = nil
        // Let any in-flight motion callback finish before the final drain.
        motionQueue.waitUntilAllOperationsAreFinished()
        queue.sync {
            drain()
            do {
                try recorder.closeOpenFrame()
            } catch {
                printToFile("sensor-stream close failed: \(error)")
            }
        }
    }

    /// Runs on `queue`.
    private func drain() {
        bufferLock.lock()
        let samples = buffer
        buffer.removeAll(keepingCapacity: true)
        bufferLock.unlock()

        let wall = Date().timeIntervalSince1970
        let uptime = ProcessInfo.processInfo.systemUptime
        do {
            // A clock change or deep sleep moves the boot-to-epoch offset: close the
            // open frame and convert this batch with the new session's offset.
            if clock.restartIfDrifted(wallEpochSeconds: wall, uptimeSeconds: uptime) {
                try recorder.closeOpenFrame()
            }
            let records = samples.compactMap { sample -> AccelRecord? in
                guard let timestamp = clock.epochMs(uptimeSeconds: sample.uptime) else { return nil }
                return UnitConversion.record(timestamp: timestamp, xG: sample.x, yG: sample.y, zG: sample.z)
            }
            try recorder.ingest(records, nowMs: Int64((wall * 1_000).rounded(.down)))
        } catch {
            printToFile("sensor-stream drain failed: \(error)")
        }
    }
}
#endif
