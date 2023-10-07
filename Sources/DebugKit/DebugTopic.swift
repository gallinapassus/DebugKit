/// A concrete type capable of representing any debug topic
public struct DebugTopic : Hashable {
    public static func == (lhs: DebugTopic, rhs: DebugTopic) -> Bool {
        lhs.level == rhs.level
    }
    public init() {
        self.bitValue = OneBitValue(value: 0)!
        self.label = nil
    }
    public init(level:Int, _ label:String? = nil) {
        precondition((0..<MemoryLayout<BitValueType>.size * 8).contains(level))
        self.bitValue = OneBitValue(uncheckedPosition: level)
        self.label = label
    }
    public init(level:OneBitValue<BitValueType>, _ label:String? = nil) {
        self.bitValue = level
        self.label = label
    }
    public typealias BitValueType = UInt64
    private let bitValue:OneBitValue<BitValueType>
    public let label: String?
    public var level:Int { bitValue.position }
    public static let allTopics:Int = (MemoryLayout<BitValueType>.size * 8) - 1
}

extension DebugTopic : ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) {
        let r = 0..<MemoryLayout<BitValueType>.size * 8
        precondition(r.contains(value))
        self.init(level: value)
    }
}
extension DebugTopic {
    /// Predefined topic, intended to represent all available topics (can be overridden)
    public static var all:DebugTopic {
        DebugTopic(
            level: OneBitValue(
                uncheckedPosition: Self.allTopics
            ),
            "all"
        )
    }
}
extension DebugTopic : Codable {
    enum CodingKeys : CodingKey { case level, label }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bitValue.position, forKey: .level)
        try container.encode(label, forKey: .label)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let p = try container.decode(Int.self, forKey: .level)
        guard let bv = OneBitValue<BitValueType>(position: p) else {
            //            let ctx = DecodingError.Context(codingPath: [CodingKeys.level],
            //                                            debugDescription: "CONTEXT")
            let r = 0..<MemoryLayout<BitValueType>.size * 8
            throw DecodingError
                .dataCorruptedError(
                    forKey: .level,
                    in: container,
                    debugDescription: "Value \(p) is an invalid value for \(CodingKeys.level.stringValue). Value must be in the range \(r)."
                )
        }
        self.bitValue = bv //SingleBitValue(position: p)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
    }
}
