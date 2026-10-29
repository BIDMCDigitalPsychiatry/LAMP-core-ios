import Foundation
import XCTest
@testable import SensorStream

/// Loads the golden vectors copied from LAMP-protocol/test-vectors/sensor-stream.
enum Fixtures {
    static func url(_ name: String) throws -> URL {
        let base = try XCTUnwrap(Bundle.module.resourceURL).appendingPathComponent("Fixtures")
        return base.appendingPathComponent(name)
    }

    static func data(_ name: String) throws -> Data {
        try Data(contentsOf: url(name))
    }

    static func json(_ name: String) throws -> Any {
        try JSONSerialization.jsonObject(with: data(name))
    }

    /// The 500 records of the main frame.
    static func records() throws -> [AccelRecord] {
        let rows = try XCTUnwrap(json("records.json") as? [[String: Any]])
        return try rows.map { row in
            AccelRecord(timestamp: try XCTUnwrap((row["timestamp"] as? NSNumber)?.int64Value),
                        x: Float(try XCTUnwrap(row["x"] as? Double)),
                        y: Float(try XCTUnwrap(row["y"] as? Double)),
                        z: Float(try XCTUnwrap(row["z"] as? Double)))
        }
    }

    /// One entry of meta.json, decoded.
    static func meta(_ key: String) throws -> FrameMetadata {
        let all = try XCTUnwrap(json("meta.json") as? [String: Any])
        let entry = try XCTUnwrap(all[key])
        let data = try JSONSerialization.data(withJSONObject: entry)
        return try JSONDecoder().decode(FrameMetadata.self, from: data)
    }

    static func edgeCase(_ key: String) throws -> [String: Any] {
        let all = try XCTUnwrap(json("edge_cases.json") as? [String: Any])
        return try XCTUnwrap(all[key] as? [String: Any])
    }

    /// Converts `[[ts, x, y, z], ...]` rows from edge_cases.json.
    static func rows(_ value: Any?) throws -> [AccelRecord] {
        let rows = try XCTUnwrap(value as? [[NSNumber]])
        return rows.map { AccelRecord(timestamp: $0[0].int64Value, x: $0[1].floatValue, y: $0[2].floatValue, z: $0[3].floatValue) }
    }

    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    /// A fresh empty directory under the temporary directory.
    static func temporaryDirectory(_ name: String = #function) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SensorStreamTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
