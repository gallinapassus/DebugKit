// DebugTopicSet could be just a typealias
// public typealias DebugTopicSet = Set<DebugTopic>
// The drawback would be that the isWildcard evaluation
// would be 'self.contains(63)' which means iterating over
// the set vs. a concrete type implementation where the
// wildcard evaluation is a simple Bool value comparison.
public struct DebugTopicSet : Hashable {
    private var values:Set<DebugTopic>
    private (set) public var isCatchAll:Bool = false
    lazy public var isCatchNone = {
        values == [DebugTopic()] || values.isEmpty
    }()
    public init(_ valueSet: Set<DebugTopic>) {
        self.values = valueSet
        self.isCatchAll = valueSet.map({ $0.level }).contains(63) // TODO:FIX
    }
    public init<T:Sequence>(_ elements: T) where T.Element == DebugTopic {
        self.init(Set(elements))
    }
    public init(_ topic: DebugTopic) {
        self.init(Set([topic]))
    }
    public static let catchAll:DebugTopicSet = DebugTopicSet(
        DebugTopic(level: 63)
    )
}
extension DebugTopicSet : Codable {
    enum CodingKeys : CodingKey { case topics }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(values, forKey: .topics)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let values = try container.decode(Set<DebugTopic>.self, forKey: .topics)
        self = DebugTopicSet(values)
    }
}
extension DebugTopicSet : SetAlgebra {
    public mutating func remove(_ member: DebugTopic) -> DebugTopic? {
        return values.remove(member)
    }
    
    public init() {
        self.values = []
    }
    
    public func union(_ other: __owned DebugTopicSet) -> DebugTopicSet {
        return DebugTopicSet(values.union(other))
    }
    
    public func intersection(_ other: DebugTopicSet) -> DebugTopicSet {
        return DebugTopicSet(values.intersection(other))
    }
    
    public func symmetricDifference(_ other: __owned DebugTopicSet) -> DebugTopicSet {
        return DebugTopicSet(values.symmetricDifference(other))
    }
    
    public mutating func insert(_ newMember: __owned DebugTopic) -> (inserted: Bool, memberAfterInsert: DebugTopic) {
        return values.insert(newMember)
    }
    
    public mutating func update(with newMember: __owned DebugTopic) -> DebugTopic? {
        return values.update(with: newMember)
    }
    
    public mutating func formUnion(_ other: __owned DebugTopicSet) {
        return values.formUnion(other)
    }
    
    public mutating func formIntersection(_ other: DebugTopicSet) {
        return values.formIntersection(other)
    }
    
    public mutating func formSymmetricDifference(_ other: __owned DebugTopicSet) {
        return values.formSymmetricDifference(other)
    }
    public func contains(_ member: DebugTopic) -> Bool {
        isCatchAll ? true : values.contains(member)
    }
}
extension DebugTopicSet : Sequence {
    public typealias Element = DebugTopic
    public func makeIterator() -> Set<DebugTopic>.Iterator  {
        return values.makeIterator()
    }
}
extension DebugTopicSet : ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = DebugTopic
    public init(arrayLiteral elements: DebugTopic...) {
        self.init(Set(elements))
    }
}
extension DebugTopicSet : CustomStringConvertible {
    public var description: String {
        return "[" + values
            .sorted(by: { $0.level < $1.level })
            .map({ $0.label ?? $0.level.description })
            .joined(separator: ", ") + "]"
    }
}
