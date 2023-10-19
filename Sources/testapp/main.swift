import Foundation
import ArgumentParser
import DebugKit

extension DebugTopic : ExpressibleByArgument {
    public init?(argument: String) {
        if argument == "all" {
            self = DebugTopic(level: 63, "all")
            return
        }
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
            help: ArgumentHelp("Enable debugging. Available levels; \(DebugTopic.allTopics.compactMap({ $0.label }).joined(separator: ", "))",
                               valueName: "level"))
    var debug:[DebugTopic] = []
    @Argument
    var file:String
    func run() throws {
        let mask = DebugTopicSet(debug.compactMap({$0}))
        dbg(.info, mask, "Selected debug topics: \(mask.description)")

        do {
            dlog(.info, mask, "reading file \(file)")
            let content = try Data(contentsOf: URL(fileURLWithPath: file))
            dbg(.info, mask, "'\(file)' \(content.description)")
        } catch let e {
            dbg(.error, mask, e.localizedDescription)
            dlog(.error, mask, "failed, \(e.localizedDescription)")
        }
    }
}

ArgumentModel.main()

extension DebugTopic {
    // Topics
    public static var info     = DebugTopic(level: 0, "info")
    public static var warning  = DebugTopic(level: 1, "warning")
    public static var error    = DebugTopic(level: 2, "error")
    public static var critical = DebugTopic(level: 3, "critical")
    // A "mask" including all topics
    public static var allTopics:DebugTopicSet = [
        .info, .warning, .error, .critical
    ]
}
