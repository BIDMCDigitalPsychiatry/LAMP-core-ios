import Foundation

/// One accelerometer sample: epoch milliseconds and m/s² per axis.
public struct AccelRecord: Equatable {
    public var timestamp: Int64
    public var x: Float
    public var y: Float
    public var z: Float

    public init(timestamp: Int64, x: Float, y: Float, z: Float) {
        self.timestamp = timestamp
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Packs records into the contract's 20-byte little-endian layout.
public enum AccelRecordPacker {
    /// Bytes per record.
    public static let recordSize = 20

    /// Sorts records by timestamp, keeping the arrival order of equal timestamps.
    public static func stableSorted(_ records: [AccelRecord]) -> [AccelRecord] {
        records
    }

    /// Packs records in the order given.
    public static func pack(_ records: [AccelRecord]) -> Data {
        Data()
    }

    /// Stable-sorts, then packs.
    public static func packFrame(_ records: [AccelRecord]) -> Data {
        Data()
    }

    /// Unpacks every whole record in `data`. Trailing bytes that don't form a
    /// whole record are ignored.
    public static func unpack(_ data: Data) -> [AccelRecord] {
        []
    }
}
