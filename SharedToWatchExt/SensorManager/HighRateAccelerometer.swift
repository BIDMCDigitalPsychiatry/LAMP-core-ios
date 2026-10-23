//  mindLAMP Consortium

#if os(iOS)
import CoreMotion
import Foundation
import SensorStream

/// Records one accelerometer tier (`lamp.accelerometer{10,20,50,100}hz`) into
/// sensor-stream frames under `Documents/SensorStream`.
///
/// CoreMotion pushes samples into an in-memory buffer; every
/// `SensorTier.drainInterval` (5 s) an `AccelerometerSession` converts the
/// buffer to records (epoch ms, m/s², Android axes) and hands them to a
/// `FrameRecorder`, which appends the open frame to disk and seals closed
/// frames for upload. In the background, updates keep arriving only while the
/// app's continuous location updates keep it running.
final class HighRateAccelerometer {

    /// The app's only `CMMotionManager` for sensor-stream tiers. Apple recommends
    /// one instance per app; only one tier runs at a time.
    static let motionManager = CMMotionManager()

    let tier: SensorTier
    private let store: FrameStore
    private let session: AccelerometerSession
    /// Serializes the session (its clock and recorder) and the store.
    private let queue = DispatchQueue(label: "digital.lamp.sensorstream.accelerometer", qos: .utility)
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "digital.lamp.sensorstream.motion"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private let bufferLock = NSLock()
    private var buffer: [MotionSample] = []
    private var drainTimer: DispatchSourceTimer?
    private(set) var isRunning = false

    init(tier: SensorTier, store: FrameStore) {
        self.tier = tier
        self.store = store
        self.session = AccelerometerSession(recorder: FrameRecorder(spec: tier.spec, store: store))
    }

    /// Seals frames left open by an earlier process, then starts sampling.
    func start() {
        let manager = Self.motionManager
        guard !isRunning, manager.isAccelerometerAvailable else { return }
        isRunning = true
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.store.recoverOpenFramesOncePerProcess()
            } catch {
                printToFile("sensor-stream recovery failed: \(error)")
            }
            do {
                try self.session.start(wallEpochSeconds: Date().timeIntervalSince1970,
                                       uptimeSeconds: ProcessInfo.processInfo.systemUptime)
            } catch {
                printToFile("sensor-stream session start failed: \(error)")
            }
        }
        bufferLock.lock()
        buffer.reserveCapacity(tier.nominalHz * Int(SensorTier.drainInterval) * 2)
        bufferLock.unlock()

        manager.accelerometerUpdateInterval = tier.accelerometerUpdateInterval
        manager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            // Read both clocks on arrival, so a drain can tell which clock session each sample belongs to.
            let sample = MotionSample(uptime: data.timestamp, xG: data.acceleration.x,
                                      yG: data.acceleration.y, zG: data.acceleration.z,
                                      receivedWallEpochSeconds: Date().timeIntervalSince1970,
                                      receivedUptimeSeconds: ProcessInfo.processInfo.systemUptime)
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
            do {
                try session.stop(takeBuffer(), wallEpochSeconds: Date().timeIntervalSince1970,
                                 uptimeSeconds: ProcessInfo.processInfo.systemUptime)
            } catch {
                printToFile("sensor-stream close failed: \(error)")
            }
        }
    }

    private func takeBuffer() -> [MotionSample] {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        let samples = buffer
        buffer.removeAll(keepingCapacity: true)
        return samples
    }

    /// Runs on `queue`.
    private func drain() {
        do {
            // The session checks clock drift per sample, so samples captured before a
            // clock change or a deep sleep keep their own session's offset.
            try session.drain(takeBuffer(), wallEpochSeconds: Date().timeIntervalSince1970,
                              uptimeSeconds: ProcessInfo.processInfo.systemUptime)
        } catch {
            printToFile("sensor-stream drain failed: \(error)")
        }
    }
}
#endif
