import Foundation
import ArgumentParser
import DebugKit

extension DebugTopic : ExpressibleByArgument {
    public init?(argument: String) {
        guard let topic = DebugTopic.allTopics.first(where: { $0.label == argument }) else {
            return nil
        }
        self = topic
    }
}
struct ArgumentModel : ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "testapp",
        abstract: "Test application",
        usage: nil,
        discussion: "",
        version: DebugKit.version.description,
        shouldDisplay: true)
    
    @Option(name: .shortAndLong,
            parsing: ArrayParsingStrategy.upToNextOption,
            help: ArgumentHelp("Enable debugging. Available levels; \(DebugTopic.allTopics.map({$0.label}).joined(separator: ", "))",
                               valueName: "level"))
    var debug:[DebugTopic] = []
    @Argument
    var file:String
    func run() throws {
        let mask = DebugTopicSet(debug.compactMap({$0}))
        dbg(.info, mask, "info-level debugging active")
        dbg(.warning, mask, "warning-level debugging active")
        dbg(.error, mask, "error-level debugging active")
        dbg(.critical, mask, "critical-level debugging active")
        dbg(.error, mask, "File '\(file)' not found")
    }
}

ArgumentModel.main()

extension DebugTopic {
    // Topics
    public static var info     = DebugTopic("info", level: 0)
    public static var warning  = DebugTopic("warning", level: 1)
    public static var error    = DebugTopic("error", level: 2)
    public static var critical = DebugTopic("critical", level: 3)
    // A "mask" including all topics
    public static var allTopics:DebugTopicSet = [
        .info, .warning, .error, .critical
    ]
}
