import XCTest
@testable import SensorStream

final class UploadPolicyTests: XCTestCase {
    func testContractResponseTable() {
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 200), .delete)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 409), .quarantine)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 400), .quarantine)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 401), .retryAfterAuthRefresh)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 403), .retryAfterAuthRefresh)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 413), .quarantine)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 500), .retryWithBackoff)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 502), .retryWithBackoff)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 503), .retryWithBackoff)
        XCTAssertEqual(UploadPolicy.action(forStatusCode: nil), .retryWithBackoff, "network error")
    }

    func testUnlistedCodesKeepTheFrame() {
        // A frame is never deleted or quarantined on a code the contract doesn't list.
        for code in [404, 408, 429, 302, 0] {
            XCTAssertEqual(UploadPolicy.action(forStatusCode: code), .retryWithBackoff, "\(code)")
        }
        XCTAssertEqual(UploadPolicy.action(forStatusCode: 201), .delete)
    }

    func testExponentialBackoff() {
        XCTAssertEqual(UploadPolicy.backoffDelay(afterFailures: 0), 0)
        XCTAssertEqual(UploadPolicy.backoffDelay(afterFailures: 1), 30)
        XCTAssertEqual(UploadPolicy.backoffDelay(afterFailures: 2), 60)
        XCTAssertEqual(UploadPolicy.backoffDelay(afterFailures: 3), 120)
        XCTAssertEqual(UploadPolicy.backoffDelay(afterFailures: 20), 3_600)
        XCTAssertEqual(UploadPolicy.backoffDelay(afterFailures: 10_000), 3_600)
    }

    func testDecodesStoredAndDuplicateResponses() throws {
        let stored = try JSONDecoder().decode(SensorStreamUploadResponse.self, from: Data(#"{"data":{"id":"abc"}}"#.utf8))
        XCTAssertEqual(stored.data.id, "abc")
        XCTAssertNil(stored.data.duplicate)
        let duplicate = try JSONDecoder().decode(SensorStreamUploadResponse.self,
                                                 from: Data(#"{"data":{"id":"abc","duplicate":true}}"#.utf8))
        XCTAssertEqual(duplicate.data.duplicate, true)
    }

    func testMaxFrameBytesIsFourMebibytes() {
        XCTAssertEqual(UploadPolicy.maxFrameBytes, 4 * 1_024 * 1_024)
    }
}
