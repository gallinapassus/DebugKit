# DebugKit

Lightweight logging.

## Include DebugKit into your project

```
import DebugKit
```

## Example(s)

Customise/setup your logging topics

```
// Setup your logging topics
extension DebugTopic {
    // Topics
    public static let info = DebugTopic("info", level: 0)
    public static let warning = DebugTopic("warning", level: 1)
    public static let error = DebugTopic("error", level: 2)
    // A allTopics "mask" including all topics
    public static let allTopics:DebugTopicSet = [
        .info, .warning, .error
    ]
}
```
Send debug messages unconditionally
```
func foobar() {
    // Send debug messages unconditionally
    dbg(.info, "All good") // sends "debug-info: All good" to stderr
    dbg(.error, "Bang!") // sends "debug-error: Bang!" to stderr
}
```
Use "mask" to selectively send debug messages 
```
func someFunction(debug mask:DebugTopicSet) {
    dbg(.error, mask, "File not found")
}

let mask:DebugTopicSet = [.info, .error]
// results into "debug-error: File not found" to be sent to stderr
someFunction(debug: mask)
```
Send debug messages to specific FileHandle
```
let handle = FileHandle.standardOutput
let mask:DebugTopicSet = [.info, .warning]
dbg(to: handle, .warning, mask, "visible")   // sends "debug-warning: visible" to stdout
dbg(to: handle, .error, mask, "not visible") // doesn't send anything to stdout
```
Use unlabeled debug levels
```
extension DebugTopic {
    // Topics
    public static let info = DebugTopic(level: 0)
    public static let telemetry = DebugTopic(level: 1)
    public static let warning = DebugTopic(level: 2)
    public static let error = DebugTopic(level: 3)
    public static let critical = DebugTopic(level: 4)
}
dbg(.critical, "Bang!") // sends "debug-4: Bang!" to stderr
```
Send debug messages unconditionally to multiple topics at once
```
// unconditional, multiple topics at once
dbg([.info, .warning, .error], "topic is active")
// results into =>
//  debug-info: topic is active
//  debug-warning: topic is active
//  debug-error: topic is active
```
Send debug messages conditionally to multiple topics at once
```
// conditional, multiple topics at once
dbg([.info, .warning, .error], [.warning], "topic is active")
// results into =>
//  debug-warning: topic is active
```
Customise the prefix, label separator, message separator and terminator
```
dbg(.telemetry, prefix: "myappname", labelSeparator: "_", messageSeparator: "; ", terminator: " ✓\n", "start") // sends "myappname_telemetry; start ✓" to stderr

// -or- for convenience
// make your own 'appdbg' function
func appdbg(to handle: FileHandle? = FileHandle.standardError,
            _ level: DebugTopic,
            _ mask: DebugTopicSet,
            _ message: @autoclosure () -> String) {
    let prefix: String = "myappname"
    let labelSeparator: String? = "_"
    let messageSeparator: String? = "; "
    let terminator:String? = " ✓\n"
    dbg(to: handle, level, mask, prefix: prefix, labelSeparator: labelSeparator, messageSeparator: messageSeparator, terminator: terminator, message())
}

appdbg(.telemetry, [.all], "start") // sends "myappname_telemetry; start ✓" to stderr
```

## Important

### Overlaps

It is possible to create overlapping DebugTopics like below

```
extension DebugTopic {
    // Topics
    public static let info = DebugTopic(level: 0, "info")
    public static let warning = DebugTopic(level: 1, "warning")
    public static let error = DebugTopic(level: 2, "error")
    public static let critical = DebugTopic(level: 3, "error") // <-- label duplicate with .error
    public static let telemetry = DebugTopic(level: 0, "telemetry") // <-- level duplicate with .info
}
```

Arguably, this can be considered as a 'feature' or a 'DebugKit bug' :-)

## Limitations

DebugKit supports 64 individual debug levels.

Levels 0-62 are for normal use and level 63 (labeled as "all") can be used to catch-all levels.

```
let mask:DebugTopicSet = [.all]

mask.contains(.info) // evaluates true
mask.contains(.all) // evaluates true
mask.contains(DebugTopic(level: 42)) // evaluates true
```
