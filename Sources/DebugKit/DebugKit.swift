import Foundation
import SemanticVersion

/// DebugKit semantic version
public let version = SemanticVersion(0, 0, 5)

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
private let logTimestampFormatter = {
    let f = DateFormatter()
    f.locale = Locale.current
    f.timeZone = TimeZone.current
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return f
}()
/// Send un-leveled timestamped logging information to `stderr` (unconditionally)
public func dlog(to handle: FileHandle? = FileHandle.standardError,
                 messageSeparator: String? = " ",
                 terminator:String? = "\n",
                 _ message: @autoclosure () -> String) {
    guard let handle = handle else { return }
    let now = Date()
    let pfx = "\(logTimestampFormatter.string(from: now))"
    let data = _dbgmsg(.all,
                       prefix: pfx,
                       labelSeparator: nil,
                       messageSeparator: messageSeparator,
                       terminator: terminator,
                       message())
    _write(to: handle, data)
}
/// Send timestamped logging information conditionally to file handle (default `stderr`)
public func dlog(to handle: FileHandle? = FileHandle.standardError,
                 _ level: DebugTopic,
                 _ mask: DebugTopicSet,
                 messageSeparator: String? = ": ",
                 terminator:String? = "\n",
                 _ message: @autoclosure () -> String) {
    
    guard let handle = handle else { return }
    guard mask.contains(level) || mask.isCatchAll else {
        return
    }
    let now = Date()
    let pfx = "\(logTimestampFormatter.string(from: now)) [\(level.label ?? level.level.description)]"
    let data:Data = _dbgmsg(level,
                            prefix: pfx,
                            labelSeparator: nil,
                            messageSeparator: messageSeparator,
                            terminator: terminator,
                            message())
    _write(to: handle, data)
}
/// Send timestamped logging information conditionally to multiple topics at once
///
/// Example:
///
///     dlog([.info, .warning, .error], "topic is active")
public func dlog(to handle: FileHandle? = FileHandle.standardError,
                 _ levels: [DebugTopic],
                 _ mask: DebugTopicSet,
                 messageSeparator: String? = ": ",
                 terminator:String? = "\n",
                 _ message: @autoclosure () -> String) {
    levels.forEach { level in
        dlog(to: handle, level, mask,
             messageSeparator: messageSeparator,
             terminator: terminator,
             message())
    }
}
/// Send timestamped logging information unconditionally to file handle (default `stderr`)
public func dlog(to handle: FileHandle? = FileHandle.standardError,
                 _ level: DebugTopic,
                 messageSeparator: String? = ": ",
                 terminator:String? = "\n",
                 _ message: @autoclosure () -> String) {
    guard let handle = handle else { return }
    let now = Date()
    let pfx = "\(logTimestampFormatter.string(from: now)) [\(level.label ?? level.level.description)]"
    let data:Data = _dbgmsg(
        level,
        prefix: pfx,
        labelSeparator: nil,
        messageSeparator: messageSeparator,
        terminator: terminator,
        message())
    _write(to: handle, data)
}
/// Send timestamped logging information unconditionally to file handle (default `stderr`)
public func dlog(to handle: FileHandle? = FileHandle.standardError,
                 _ levels: [DebugTopic],
                 messageSeparator: String? = ": ",
                 terminator:String? = "\n",
                 _ message: @autoclosure () -> String) {
    guard let handle = handle else { return }
    levels.forEach { level in
        dlog(to: handle, level, messageSeparator: messageSeparator, terminator: terminator, message())
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
    // label and labelSeparator are written
    // *only if* labelSeparator != nil
    if let labelSep = labelSeparator {
        if let label = level.label {
            concat.append(labelSep)
            // write label (string)
            concat.append(label)
        }
        else {
            concat.append(labelSep)
            // write label level (int)
            concat.append(level.level.description)
        }
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
