import XCTest
@testable import DebugKit

extension DebugTopic {
    public static var info = DebugTopic(level: 0, "info")
    public static var warning = DebugTopic(level: 1, "warning")
    public static var error = DebugTopic(level: 2, "error")
    public static var telemetry = DebugTopic(level: 3, "telemetry")
    public static var critical = DebugTopic(level: 4) // unlabeled
    public static var labeledEmpty = DebugTopic(level: 61, "") // labeled as ""
    
    public static var allTopics:DebugTopicSet = [
        .info, .warning, .error, .telemetry, .labeledEmpty, .critical
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

        func foobar() {
            // Send debug messages unconditionally
            dbg(.info, "All good") // sends "debug-info: All good" to stderr
            dbg(.error, "Bang!") // sends "debug-error: Bang!" to stderr
        }

        foobar()

    }
    func test_readme_2() {

        func someFunction(debug mask:DebugTopicSet) {
            // sends "debug-error: File not found" to stderr when .error is included in the mask
            dbg(.error, mask, "File not found")
        }

        let mask:DebugTopicSet = [.info, .error]
        // results into "debug-error: File not found" to be sent to stderr
        someFunction(debug: mask)

    }
    func test_readme_3() {

        let handle = FileHandle.standardOutput
        let mask:DebugTopicSet = [.info, .warning]
        dbg(to: handle, .warning, mask, "visible") // sends "debug-warning: visible" to stdout
        dbg(to: handle, .error, mask, "not visible") // doesn't send anything to stdout

    }
    func test_readme_4() {
        dbg(.critical, "Bang!") // sends "debug-4: Bang!" to stderr
    }
    func test_readme_5() {
        dbg(.telemetry, prefix: "myappname", labelSeparator: "_", messageSeparator: "; ", terminator: " ✓\n", "start") // sends "myappname_telemetry; start ✓" to stderr

        // -or-
        // customise your own 'dbg'
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
    }
    func test_readme_6() {
        let mask:DebugTopicSet = [.all]
        
        _ = mask.contains(.info) // evaluates true
        _ = mask.contains(.all) // evaluates true
        _ = mask.contains(DebugTopic(level: 42)) // evaluates true

        XCTAssertTrue(mask.contains(.info)) // evaluates true
        XCTAssertTrue(mask.contains(.all))  // evaluates true
        XCTAssertTrue(mask.contains(DebugTopic(level: 42))) // evaluates true
    }
    func test_timestamped() {
//        let mask = DebugTopicSet([.info, .warning, .error, .telemetry])
        dbg(.info, [.all], prefix: "\(Date())", labelSeparator: ":", "Timestamped debug entry.")
    }
    func test_formatting() {
        let tests:[((DebugTopic, String, String?, String?, String?, String), String)] = [
            ((.info, "debug", nil, nil, nil, "kala"), "debuginfokala"),
            ((.info, "debug", nil, nil, "\n", "kala"), "debuginfokala\n"),
            ((.info, "DBG", nil, nil, "\n", "kala"), "DBGinfokala\n"),
            ((.info, "", nil, nil, "\n", "kala"), "infokala\n"),
            ((.critical, "debug", nil, nil, "\n", "kala"), "debugkala\n"),
            ((.critical, "debug", "-", nil, "\n", "kala"), "debugkala\n"),
            ((.info, "debug", "-", nil, "\n", "kala"), "debug-infokala\n"),
            ((.info, "debug", "-", ">", "\n", "kala"), "debug-info>kala\n"),
            ((.info, "debug", nil, ">", "\n", "kala"), "debuginfo>kala\n"),
            ((.critical, "debug", nil, ">", "\n", "kala"), "debug>kala\n"),
            ((.critical, "", nil, nil, "\n", "kala"), "kala\n"),
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
        dbg(.labeledEmpty, "ok")
        dbg(.labeledEmpty, labelSeparator: nil, "ok")
        dbg(.labeledEmpty, labelSeparator: "_", "ok")
        
        dbg(.critical, "click")
        dbg(.critical, messageSeparator: nil, "click")
        dbg(.critical, messageSeparator: ">", "click")
        dbg(.critical, labelSeparator: ":", "click")
        dbg(.critical, labelSeparator: nil, "click")
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
        dbg(to: handle, .info, [.info, .warning], "abc")
    }
    func test_topic_all() {
        let handle = FileHandle.standardError
        let infoMask = DebugTopicSet([.info])
        let allMask = DebugTopicSet([.all])
        if infoMask.contains(.info) {
            dbg(to: handle, .warning, "ok \(#line)")
            dbg(to: handle, .error, "ok \(#line)")
            dbg(to: handle, .info, "ok \(#line)")
            dbg(to: handle, .all, "ok \(#line)")
        }
        if infoMask.contains(.all) {
            dbg(to: handle, .warning, "test failed, if you see this \(#line)")
            dbg(to: handle, .error, "test failed, if you see this \(#line)")
            dbg(to: handle, .info, "test failed, if you see this \(#line)")
            dbg(to: handle, .all, "test failed, if you see this \(#line)")
        }
        if allMask.contains(.info) {
            dbg(to: handle, .warning, "ok \(#line)")
            dbg(to: handle, .error, "ok \(#line)")
            dbg(to: handle, .info, "ok \(#line)")
            dbg(to: handle, .all, "ok \(#line)")
        }
        if allMask.contains(.all) {
            dbg(to: handle, .warning, "ok \(#line)")
            dbg(to: handle, .error, "ok \(#line)")
            dbg(to: handle, .info, "ok \(#line)")
            dbg(to: handle, .all, "ok \(#line)")
        }
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
