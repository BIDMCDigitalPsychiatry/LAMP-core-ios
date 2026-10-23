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

/// Packs records into the contract's 20-byte little-endian layout:
/// `int64 timestamp, float32 x, float32 y, float32 z`.
public enum AccelRecordPacker {
    /// Bytes per record.
    public static let recordSize = 20

    /// Sorts records by timestamp, keeping the arrival order of equal timestamps.
    public static func stableSorted(_ records: [AccelRecord]) -> [AccelRecord] {
        // The standard library doesn't promise a stable sort, so the index breaks ties.
        records.enumerated()
            .sorted { $0.element.timestamp != $1.element.timestamp
                ? $0.element.timestamp < $1.element.timestamp
                : $0.offset < $1.offset }
            .map(\.element)
    }

    /// Packs records in the order given.
    public static func pack(_ records: [AccelRecord]) -> Data {
        var data = Data(count: records.count * recordSize)
        data.withUnsafeMutableBytes { buffer in
            for (i, record) in records.enumerated() {
                let offset = i * recordSize
                buffer.storeBytes(of: record.timestamp.littleEndian, toByteOffset: offset, as: Int64.self)
                buffer.storeBytes(of: record.x.bitPattern.littleEndian, toByteOffset: offset + 8, as: UInt32.self)
                buffer.storeBytes(of: record.y.bitPattern.littleEndian, toByteOffset: offset + 12, as: UInt32.self)
                buffer.storeBytes(of: record.z.bitPattern.littleEndian, toByteOffset: offset + 16, as: UInt32.self)
            }
        }
        return data
    }

    /// Stable-sorts, then packs.
    public static func packFrame(_ records: [AccelRecord]) -> Data {
        pack(stableSorted(records))
    }

    /// Unpacks every whole record in `data`. Trailing bytes that don't form a
    /// whole record are ignored.
    public static func unpack(_ data: Data) -> [AccelRecord] {
        let count = data.count / recordSize
        return data.withUnsafeBytes { buffer in
            (0..<count).map { i in
                let offset = i * recordSize
                return AccelRecord(
                    timestamp: Int64(littleEndian: buffer.loadUnaligned(fromByteOffset: offset, as: Int64.self)),
                    x: Float(bitPattern: UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: offset + 8, as: UInt32.self))),
                    y: Float(bitPattern: UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: offset + 12, as: UInt32.self))),
                    z: Float(bitPattern: UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: offset + 16, as: UInt32.self))))
            }
        }
    }
}
