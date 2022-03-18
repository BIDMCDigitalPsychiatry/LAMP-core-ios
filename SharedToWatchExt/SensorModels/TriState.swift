// mindLAMP

import Foundation

// https://stackoverflow.com/questions/47266862/encode-nil-value-as-null-with-jsonencoder
/**
 At first we set "null" , and it encode as string to wirte to a file,
 When read from file, means when decode, we will convert to .nullValue. So that when send to server it will pass null instead of "null"
 */
public enum Tristate: ExpressibleByNilLiteral, Codable {
    
    /// Null
    case nullValue
    
    /// The presence of a value, stored as `Wrapped`.
    case some(String)
    
    /// no value. just nil
    case noValue
    
    /// Creates an instance initialized with .pending.
    public init() {
        self = .noValue // nil
    }
    
    /// Creates an instance initialized with .none.
    public init(nilLiteral: ()) {
        self = .nullValue // null
    }
    
    /// Creates an instance that stores the given value.
    public init(_ some: String?) {
        if let source = some {
            self = .some(source)
        } else {
            //self = .nullValue
            self = .some("null")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .nullValue:
            try container.encodeNil()
        case .some(let wrapped):
            try wrapped.encode(to: encoder)
        case .noValue: break // do nothing
        }
    }
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()

            if let value = try? container.decode(String.self) {
                if value == "null" {
                    self = .nullValue
                } else {
                    self = .some(value)
                }
            } else if container.decodeNil() {
                self = .nullValue
            } else {
                self = .noValue
            }
        } catch {
            assertionFailure("ERROR: \(error)")
            self = .noValue
        }
    }
}
