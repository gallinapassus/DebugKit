import XCTest
@testable import DebugKit

extension DebugTopic {
    public static var info = DebugTopic(level: 0, "info")
    public static var warning = DebugTopic(level: 1, "warning")
    public static var error = DebugTopic(level: 2, "error")
    public static var telemetry = DebugTopic(level: 3, "telemetry")
    public static var status = DebugTopic(level: 61, "") // labeled as ""
    public static var interaction = DebugTopic(level: 62) // unlabeled
    public static var unlabeled = DebugTopic(level: 63, "all")
    
    public static var allTopics:DebugTopicSet = [
        .info, .warning, .error, .telemetry, .interaction
    ]
}
// TODO: Turn "tests" into actual tests :-)
final class DebugKitTests: XCTestCase {
    func test_version() {
        print("DebugKit", DebugKit.version)
        XCTAssertFalse(DebugKit.version.isStable)
    }
    func test_SingleBitValue() {
        for i in 0..<MemoryLayout<UInt64>.size * 8 {
            let topic = DebugTopic(level: i, "a")
            XCTAssertEqual(topic.level, i)
            XCTAssertEqual(topic.label, "a")
        }        
    }
    func test_readme_1() throws {
        let mask = DebugTopic.allTopics
        dbg(.info, mask, "info")
    }
    func test_readme_2() {
        // Select the debug messages (mask) you are interested in
        let mask = DebugTopicSet([.error])
        dbg(.info, mask, "All good") // doesn't send anything to stderr
        dbg(.error, mask, "Bang!") // sends "debug-error: Bang!" to stderr
    }
    func test_readme_3() {
        // Select the debug messages (mask) you are interested in
        dbg(DebugTopic(level: 63, "critical"), "Burn!") // sends "debug-critical: Burn!" to stderr
    }
    func test_timestamped() {
        let mask = DebugTopicSet([.info, .warning, .error, .telemetry, .interaction])
        dbg(.info, mask, prefix: "\(Date())", labelSeparator: ":", "Timestamped debug entry.")
    }
    func test_formatting() {
        let tests:[((DebugTopic, String, String?, String?, String?, String), String)] = [
            ((.info, "debug", nil, nil, nil, "kala"), "debuginfokala"),
            ((.info, "debug", nil, nil, "\n", "kala"), "debuginfokala\n"),
            ((.info, "DBG", nil, nil, "\n", "kala"), "DBGinfokala\n"),
            ((.info, "", nil, nil, "\n", "kala"), "infokala\n"),
            ((.unlabeled, "debug", nil, nil, "\n", "kala"), "debugkala\n"),
            ((.unlabeled, "debug", "-", nil, "\n", "kala"), "debugkala\n"),
            ((.info, "debug", "-", nil, "\n", "kala"), "debug-infokala\n"),
            ((.info, "debug", "-", ">", "\n", "kala"), "debug-info>kala\n"),
            ((.info, "debug", nil, ">", "\n", "kala"), "debuginfo>kala\n"),
            ((.unlabeled, "debug", nil, ">", "\n", "kala"), "debug>kala\n"),
            ((.unlabeled, "", nil, nil, "\n", "kala"), "kala\n"),
            ((.info, "debug", "_", ":", "[EOF]\n", "kala"), "debug_info:kala[EOF]\n"),
        ]
        for ((topic, prefix, lsep, msep, term, msg),expected) in tests {
            dbg(topic, prefix: prefix,
                labelSeparator: lsep, messageSeparator: msep, terminator: term,
                msg)
            print(expected, terminator: "")
            print("---")
        }
        dbg(.info, "message")
        dbg(.info, prefix: "dbg", "message")
        dbg(.info, labelSeparator: "_", "message")
        dbg(.info, messageSeparator: "->", "message")
        dbg(.info, terminator: "⮐\n", "message")
        dbg(.info, prefix: "dbg", labelSeparator: "_", "message")
        dbg(.info, prefix: "dbg", messageSeparator: "->", "message")
        dbg(.info, prefix: "dbg", labelSeparator: nil, messageSeparator: "->", "message")
    }
    func test_unleveled() {
        dbg("kala")
        dbg(prefix: "dbg", "kala")
        dbg(prefix: "dbg", messageSeparator: ">", "kala")
    }
    func test_unlabeled() {
        dbg(.status, "ok")
        dbg(.status, labelSeparator: nil, "ok")
        dbg(.status, labelSeparator: "_", "off")
        
        dbg(.interaction, "click")
        dbg(.interaction, messageSeparator: nil, "click")
        dbg(.interaction, messageSeparator: ">", "click")
        dbg(.interaction, labelSeparator: ":", "click")
        dbg(.interaction, labelSeparator: nil, "click")
    }
    func test_init_with_level() {
        let warning = DebugTopic(integerLiteral: 1)
        XCTAssertEqual(warning.level, 1)
        XCTAssertNil(warning.label)
        dbg(1, "Disk space low")
        dbg(9, "Getting hot here...")
    }
    func test_init_with_mask_array_literal() {
        let handle = FileHandle.standardError
        dbg(to: handle, .warning, [.info, .warning], "visible")
        dbg(to: handle, .error, [.info, .warning], "not visible")
        dbg(to: handle, .info, [.info, .warning], { "abc" }())
    }
    func test_codable_singlebitvalue() {
        for i in 0..<MemoryLayout<UInt64>.size * 8 {
            let bitvalue = SingleBitValue(position: i)
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let encoded = try encoder.encode(bitvalue)
                guard let _ = String(data: encoded, encoding: .utf8) else {
                    XCTFail()
                    return
                }
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(SingleBitValue.self, from: encoded)
                XCTAssertEqual(bitvalue, decoded)
            } catch let e {
                print(e)
                XCTFail()
            }
            do {
                let encoder = PropertyListEncoder()
                let encoded = try encoder.encode(bitvalue)
                let decoder = PropertyListDecoder()
                let decoded = try decoder.decode(SingleBitValue.self, from: encoded)
                XCTAssertEqual(bitvalue, decoded)
            } catch let e {
                print(e)
                XCTFail()
            }
        }
        for i in 2..<MemoryLayout<UInt64>.size * 8 {
            do {
                let invalid = "{ \"value\": \(UInt64(SingleBitValue(position: i).value - 1)) }"
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(SingleBitValue.self,
                                                 from: invalid.data(using: .utf8)!)
                XCTFail("\(i): \(UInt64(SingleBitValue(position: i).value - 1)) decoded = \(decoded)")
            } catch let e {
                XCTAssertTrue(type(of: e) is DecodingError.Type)
            }
        }
    }
    func test_codable_debugtopic() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(DebugTopic.telemetry)
            guard let _ = String(data: encoded, encoding: .utf8) else {
                XCTFail()
                return
            }
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DebugTopic.self, from: encoded)
            XCTAssertEqual(DebugTopic.telemetry, decoded)
        } catch let e {
            print(e)
            XCTFail()
        }
        do {
            let encoder = PropertyListEncoder()
            let encoded = try encoder.encode(DebugTopic.telemetry)
            let decoder = PropertyListDecoder()
            let decoded = try decoder.decode(DebugTopic.self, from: encoded)
            XCTAssertEqual(DebugTopic.telemetry, decoded)
        } catch let e {
            print(e)
            XCTFail()
        }
    }
}
