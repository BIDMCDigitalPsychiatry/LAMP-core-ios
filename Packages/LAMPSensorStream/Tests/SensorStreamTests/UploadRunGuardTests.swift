import XCTest
@testable import SensorStream

final class UploadRunGuardTests: XCTestCase {
    private final class Counter {
        private let lock = NSLock()
        private var value = 0
        func increment() { lock.lock(); value += 1; lock.unlock() }
        var count: Int { lock.lock(); defer { lock.unlock() }; return value }
    }

    func testExpiryCancelsTheRequestAndEndsTheTaskRightAway() {
        let ended = Counter(), cancelled = Counter()
        let run = UploadRunGuard(endBackgroundTask: ended.increment)
        XCTAssertTrue(run.begin(cancel: cancelled.increment))
        run.expire()
        XCTAssertEqual(cancelled.count, 1)
        XCTAssertEqual(ended.count, 1, "the expiration handler must end the task itself")
        XCTAssertTrue(run.isExpired)
        // The cancelled request's completion later finishes the run; the task isn't ended twice.
        run.finish()
        run.expire()
        XCTAssertEqual(ended.count, 1)
        XCTAssertTrue(run.isExpired)
    }

    func testNoRequestStartsAfterExpiry() {
        // Expiry fires while a completion handler is between frames.
        let ended = Counter(), cancelled = Counter()
        let run = UploadRunGuard(endBackgroundTask: ended.increment)
        XCTAssertTrue(run.begin(cancel: {}))
        run.expire()
        XCTAssertFalse(run.begin(cancel: cancelled.increment), "the next frame must not start")
        XCTAssertEqual(cancelled.count, 0)
        XCTAssertEqual(ended.count, 1)
    }

    func testFinishWithoutExpiryEndsOnce() {
        let ended = Counter()
        let run = UploadRunGuard(endBackgroundTask: ended.increment)
        XCTAssertTrue(run.begin(cancel: {}))
        run.finish()
        run.finish()
        run.expire()
        XCTAssertEqual(ended.count, 1)
        XCTAssertFalse(run.isExpired)
    }

    func testConcurrentExpiryAndFinishEndOnce() {
        for _ in 0..<200 {
            let ended = Counter()
            let run = UploadRunGuard(endBackgroundTask: ended.increment)
            DispatchQueue.concurrentPerform(iterations: 8) { i in
                if i % 2 == 0 { run.expire() } else { run.finish() }
            }
            XCTAssertEqual(ended.count, 1)
        }
    }
}
