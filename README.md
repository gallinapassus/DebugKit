# DebugKit

Lightweight logging.

## Include DebugKit into your project

```
import DebugKit
```

## Example

Customise/setup your logging topics

```
// Setup your logging topics
extension DebugTopic {
    // Topics
    public static let info = DebugTopic("info", level: 0)
    public static let warning = DebugTopic("warning", level: 1)
    public static let error = DebugTopic("error", level: 2)
    // A "mask" including all topics
    public static let allTopics:DebugTopicSet = [
        .info, .warning, .error
    ]
}
```
Send debug messages unconditionally
```
func foobar() {
    // Send debug messages unconditionally
    dbg(.info,"All good") // sends "debug-info: All good" to stderr
    dbg(.error, "Bang!") // sends "debug-error: Bang!" to stderr
}
```
Use "mask" to selectively send debug messages 
```
func allLevels() {
    // Select the debug messages (mask) you are interested in
    let mask = DebugTopic.allTopics
    dbg(.info, mask, "All good") // sends "debug-info: All good" to stderr
}
func selectedLevels() {
    // Select the debug messages (mask) you are interested in
    let mask = DebugTopicSet([.error])
    dbg(.info, mask, "All good") // doesn't send anything to stderr
    dbg(.error, mask, "Bang!") // sends "debug-error: Bang!" to stderr
}
```
Send debug messages to specific FileHandle
```
let handle = FileHandle.standardError
dbg(to: handle, .warning, [.info, .warning], "visible")
dbg(to: handle, .error, [.info, .warning], "not visible")
```

## Important

### DebugTopic

It is possible to use dbg() like...
```
dbg(DebugTopic("critical", level: 3), "Burn!") // sends "debug-critical: Burn!" to stderr
```
...but it is quite cumbersome. Extending the DebugTopic with static topics makes the use shorter and quicker with automatic suggestions/completions.
```
extension DebugTopic {
    // Topics
    public static let info     = DebugTopic("info", level: 0)
    public static let warning  = DebugTopic("warning", level: 1)
    public static let error    = DebugTopic("error", level: 2)
    public static let critical = DebugTopic("critical", level: 3)
}
```
Now, same as above, but quicker and cleaner

```
dbg(.critical, "Burn!") // sends "debug-critical: Burn!" to stderr
```

### Overlaps

It is possible to create overlapping DebugTopics like below

```
extension DebugTopic {
    // Topics
    public static let info = DebugTopic("info", level: 0)
    public static let warning = DebugTopic("warning", level: 1)
    public static let error = DebugTopic("error", level: 2)
    public static let critical = DebugTopic("error", level: 3) // <-- label duplicate with .error
    public static let telemetry = DebugTopic("telemetry", level: 0) // <-- level duplicate with .info
}
```

Arguably, this can be considered as a 'feature' or a 'developer error'.

## Limitations

DebugKit supports 64 individual debug levels (levels 0-62) for normal use and one pre-defined 'catch-all' level (level 63).

