import Foundation
import SemanticVersion

/// DebugKit semantic version
public let version = SemanticVersion(0, 0, 3)

/// A concrete type capable of representing any debug topic
public struct DebugTopic : Hashable, Codable {
    public static func == (lhs: DebugTopic, rhs: DebugTopic) -> Bool {
        lhs.level == rhs.level
    }
    public init(level:Int, _ label:String? = nil) {
        self.bitValue = SingleBitValue(position: level)
        self.label = label
    }
    private let bitValue:SingleBitValue
    public let label: String?
    public var level:Int { bitValue.position }
    public static let allTopics:Int = (MemoryLayout<UInt64>.size * 8) - 1
}
extension DebugTopic : ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) {
        self.init(level: value)
    }
}
extension DebugTopic {
    /// Predefined topic, intended to represent all available topics (can be overridden)
    public static var all:DebugTopic { DebugTopic(level: 63, "all") }
}

/// Typealias for a set of debug topics
// MARK: -
// DebugTopicSet could be just a typealias
// public typealias DebugTopicSet = Set<DebugTopic>
// The drawback would be that the isWildcard evaluation
// would be 'self.contains(63)' which means iterating over
// the set vs. a concrete type implementation where the
// wildcard evaluation is a simple Bool value comparison.
public struct DebugTopicSet : Hashable, Codable {
    private var values:Set<DebugTopic>
    private (set) public var isCatchAll:Bool = false
    public init(_ valueSet: Set<DebugTopic>) {
        self.values = valueSet
        self.isCatchAll = valueSet.map({ $0.level }).contains(63)
    }
    public init<T:Sequence>(_ elements: T) where T.Element == DebugTopic {
        self.init(Set(elements))
    }
    public init(_ topic: DebugTopic) {
        self.init(Set([topic]))
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
// MARK: -
/// A concrete type storing an UInt64 value with single bit (or no bits) set.
public struct SingleBitValue: Codable, Hashable {
    public let value:UInt64
    init(value: UInt64) {
        precondition(value.nonzeroBitCount <= 1,
                     "Invalid value \(value). Value must be either 0 or any other UInt64 value wich has just one bit set.")
        self.value = value
    }
    init(position: Int) {
        let r = 0..<MemoryLayout.size(ofValue: position) * 8
        precondition(position >= 0 &&
                     r.contains(position),
                     "Invalid position \(position). Position must be in range \(r)")
        self.value = 1 << position
    }
    var position:Int { value.trailingZeroBitCount }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let v = try container.decode(UInt64.self, forKey: .value)
        guard v.nonzeroBitCount <= 1 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [CodingKeys.value],
                                      debugDescription: "Invalid value \(v). Value must be either 0 or any other UInt64 value wich has just one bit set.",
                                      underlyingError: nil))
        }
        self.value = v
    }
}
// MARK: -
/// Send un-leveled debug information to `stderr` (unconditionally)
public func dbg(to handle: FileHandle? = FileHandle.standardError,
                prefix:String = "debug",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {
    guard let handle = handle else { return }
    let data = _dbgmsg(.all,
                       prefix: prefix,
                       messageSeparator: messageSeparator,
                       terminator: terminator,
                       message())
    _write(to: handle, data)
}
/// Send debug information conditionally to file handle (default `stderr`)
public func dbg(to handle: FileHandle? = FileHandle.standardError,
                _ level: DebugTopic,
                _ mask: DebugTopicSet,
                prefix: String = "debug",
                labelSeparator: String? = "-",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {

    guard let handle = handle else { return }
    guard mask.contains(level) || mask.isCatchAll else {
        return
    }
    let data:Data = _dbgmsg(level,
                            prefix: prefix,
                            labelSeparator: labelSeparator,
                            messageSeparator: messageSeparator,
                            terminator: terminator,
                            message())
    _write(to: handle, data)
}
/// Send debug information conditionally to multiple topics at once
///
/// Example:
///
///     dbg([.info, .warning, .error], "topic is active")
public func dbg(to handle: FileHandle? = FileHandle.standardError,
                _ levels: [DebugTopic],
                _ mask: DebugTopicSet,
                prefix: String = "debug",
                labelSeparator: String? = "-",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {
    levels.forEach { level in
        dbg(to: handle, level, mask,
            prefix: prefix,
            labelSeparator: labelSeparator,
            messageSeparator: messageSeparator,
            terminator: terminator,
            message())
    }
}
/// Send debug information unconditionally to file handle (default `stderr`)
public func dbg(to handle: FileHandle? = FileHandle.standardError,
                _ level: DebugTopic,
                prefix: String = "debug",
                labelSeparator: String? = "-",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {
    
    guard let handle = handle else { return }
    let data:Data = _dbgmsg(level,
                            prefix: prefix,
                            labelSeparator: labelSeparator,
                            messageSeparator: messageSeparator,
                            terminator: terminator,
                            message())
    _write(to: handle, data)
}
/// Send debug information unconditionally to file handle (default `stderr`)
public func dbg(to handle: FileHandle? = FileHandle.standardError,
                _ levels: [DebugTopic],
                prefix: String = "debug",
                labelSeparator: String? = "-",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {
    levels.forEach { level in
        dbg(to: handle, level, [.all],
            prefix: prefix,
            labelSeparator: labelSeparator,
            messageSeparator: messageSeparator,
            terminator: terminator,
            message())
    }
}
/// Get debug message as `Data`
@inline(__always)
fileprivate func _dbgmsg(_ level:DebugTopic,
                         prefix:String = "debug",
                         labelSeparator:String? = "-",
                         messageSeparator:String? = ": ",
                         terminator:String? = "\n",
                         _ message: String) -> Data {

    var concat:String = ""
    if prefix.isEmpty == false {
        concat.append(prefix)
    }
    if let label = level.label {
        if let labelSep = labelSeparator {
            concat.append(labelSep)
        }
        concat.append(label)
    }
    else {
        if let labelSep = labelSeparator {
            concat.append(labelSep)
        }
        concat.append(level.level.description)
    }
    if let msgSeparator = messageSeparator {
        concat.append(msgSeparator)
    }
    if message.isEmpty == false {
        concat.append(message)
    }
    if let term = terminator {
        concat.append(term)
    }
    return Data(concat.utf8)
}
// MARK: -
@inline(__always)
fileprivate func _write(to handle: FileHandle, _ data:Data) {
    handle.write(data)
#if os(macOS)
    if #available(macOS 10.15, *) {
        try? handle.synchronize()
    } else {
        // no flushing
    }
#elseif os(iOS)
    if #available(iOS 13.0, *) {
        try? handle.synchronize()
    } else {
        // no flushing
    }
#else
#endif
}
