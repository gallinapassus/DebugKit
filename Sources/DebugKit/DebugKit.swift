import Foundation
import SemanticVersion

/// DebugKit semantic version
public let version = SemanticVersion(0, 0, 1)

/// A concrete type capable of representing any debug topic
public struct DebugTopic : Hashable, Codable {
    public static func == (lhs: DebugTopic, rhs: DebugTopic) -> Bool {
        lhs.level == rhs.level
    }
    public init(_ label:String, level:Int) {
        self.label = label
        self.bitValue = SingleBitValue(position: level)
    }
    private let bitValue:SingleBitValue
    public let label: String
    public var level:Int { bitValue.position }
}
/// Typealias for a set of debug topics
// MARK: -
public typealias DebugTopicSet = Set<DebugTopic>
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
/// Send debug information to `stderr`
public func dbg(_ level:DebugTopic,
                _ mask:DebugTopicSet,
                prefix:String = "debug",
                labelSeparator: String? = "-",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {
    guard mask.contains(level) else {
        return
    }
    let data = _dbgmsg(level,
                       prefix: prefix,
                       labelSeparator: labelSeparator,
                       messageSeparator: messageSeparator,
                       terminator: terminator,
                       message())
    FileHandle.standardError.write(data)
    fflush(stderr)
}
/// Send debug information to `stderr` unconditionally
public func dbg(_ level:DebugTopic,
                prefix:String = "debug",
                labelSeparator: String? = "-",
                messageSeparator: String? = ": ",
                terminator:String? = "\n",
                _ message: @autoclosure () -> String) {
    let data = _dbgmsg(level,
                       prefix: prefix,
                       labelSeparator: labelSeparator,
                       messageSeparator: messageSeparator,
                       terminator: terminator,
                       message())
    FileHandle.standardError.write(data)
    fflush(stderr)
}
// MARK: - extensions
extension FileHandle {
    /// Send debug information to specific `FileHandle`
    public func dbg(_ level:DebugTopic,
                    _ mask:DebugTopicSet,
                    prefix:String = "debug",
                    labelSeparator: String? = "-",
                    messageSeparator: String? = ": ",
                    terminator:String? = "\n",
                    _ message: @autoclosure () -> String) {
        guard mask.contains(level) else {
            return
        }
        let data = _dbgmsg(level,
                           prefix: prefix,
                           labelSeparator: labelSeparator,
                           messageSeparator: messageSeparator,
                           terminator: terminator,
                           message())
        write(data)
    }
    /// Send debug information to specific `FileHandle` unconditionally
    public func dbg(_ level:DebugTopic,
                    prefix:String = "debug",
                    labelSeparator: String? = "-",
                    messageSeparator: String? = ": ",
                    terminator:String? = "\n",
                    _ message: @autoclosure () -> String) {
        let data = _dbgmsg(level,
                           prefix: prefix,
                           labelSeparator: labelSeparator,
                           messageSeparator: messageSeparator,
                           terminator: terminator,
                           message())
        write(data)
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
    if level.label.isEmpty == false {
        if let labelSep = labelSeparator {
            concat.append(labelSep)
        }
        concat.append(level.label)
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
