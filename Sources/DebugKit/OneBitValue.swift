/// A generic type holding either a value which has no bits
/// set (value of zero) or a value which has only a single bit set.
public struct OneBitValue<T:FixedWidthInteger&Codable>: Hashable {
    /// A value with no bits set.
    public static var zero:OneBitValue { .init() }
    /// Raw value.
    public let value:T
    /// Initialize a value with no bits set.
    public init() {
        self.value = 0
    }
    /// Initialize safely with raw value.
    public init?(value: T) {
        guard value.nonzeroBitCount < 2 else { return nil }
        self.value = value
    }
    /// Initialize unsafely with raw value.
    ///
    /// - Important: Will raise an error (precondition) if initialized
    /// with value which has more than one bit set.
    public init(uncheckedBounds: T) {
        precondition(uncheckedBounds.nonzeroBitCount < 2,
                     "Invalid value \(uncheckedBounds). Value \(uncheckedBounds) has more than one bit set.")
        self.value = uncheckedBounds
    }
    /// Initialize safely with bit position.
    public init?(position: Int) {
        let r = 0..<MemoryLayout<T>.size * 8
        guard position >= 0, r.contains(position) else { return nil }
        self.value = 1 << position
    }
    /// Initialize unsafely with bit position.
    ///
    /// - Important: Will raise an error (precondition) if initialized
    /// with bit position which is out of bounds for underlying value type.
    public init(uncheckedPosition: Int) {
        let r = 0..<MemoryLayout<T>.size * 8
        precondition(uncheckedPosition >= 0 &&
                     r.contains(uncheckedPosition),
                     "Invalid position \(uncheckedPosition). Position must be in range \(r)")
        self.value = 1 << uncheckedPosition
    }
    /// Indicates if this is a value which has no bits set
    public var isZero:Bool { value == 0 }
    /// Position of the set bit.
    ///
    /// - Returns: Position of the set bit.
    /// - Important: Will return `MemoryLayout<Self.BitValueType>.size * 8` for
    /// value which has no bits set. In other words, will return the count
    /// of zero bits.
    public var position:Int { value.trailingZeroBitCount }
}
extension OneBitValue : Codable {
    enum CodingKeys : CodingKey { case position }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .position)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let v = try container.decode(T.self, forKey: .position)
        guard v.nonzeroBitCount <= 1 else {
            let msg = "Invalid value \(v). Value must be either 0 or any other \(type(of: T.self)) value wich has just one bit set."
            throw DecodingError
                .dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.position],
                    debugDescription: msg,
                    underlyingError: nil))
        }
        self.value = v
    }
}
extension OneBitValue : ExpressibleByIntegerLiteral {
    /// Initialize unsafely with bit position.
    public init(integerLiteral position: Int) {
        guard let bv = OneBitValue(position: position) else {
            let r = 0..<MemoryLayout<T>.size * 8
            fatalError("Invalid position \(position). Must be in range \(r).")
        }
        self = bv
    }
    
    public typealias IntegerLiteralType = Int
}
