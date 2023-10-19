import XCTest
import Foundation
import Darwin
@testable import DebugKit

extension DebugTopic {
    public static var info = DebugTopic(level: 0, "info")
    public static var warning = DebugTopic(level: 1, "warning")
    public static var error = DebugTopic(level: 2, "error")
    public static var telemetry = DebugTopic(level: 3, "telemetry")
    public static var critical = DebugTopic(level: 4) // unlabeled
    public static var labeledEmpty = DebugTopic(level: 61, "") // labeled as ""
    
    public static var allTopics:DebugTopicSet = [
        .info, .warning, .error, .telemetry, .critical, .labeledEmpty
    ]
}
final class DebugKitTests: XCTestCase {
    var handle:FileHandle = FileHandle.standardError
    var path:String! = nil
    override func setUp() {
        let tmpFilename = String(
            (0..<8).map({ _ in String("abc".randomElement()!) }).joined()
        )
        if FileManager.default.createFile(atPath: tmpFilename, contents: nil) {
            self.path = tmpFilename
            if let h = FileHandle(forWritingAtPath: tmpFilename) {
                self.handle = h
            }
            else {
                fatalError("\(#function) failed")
            }
        }
        else {
            fatalError("\(#function) failed")
        }
    }
    override func tearDown() {
        do {
            try self.handle.close()
        } catch {
            fatalError(error.localizedDescription)
        }
        if let path = path {
            do { try FileManager.default.removeItem(atPath: path) }
            catch {
                fatalError("failed to remove \(path)")
            }
        }
    }
    //    private var stack:[String] = []
    func test_version() {
        print("DebugKit", DebugKit.version)
        XCTAssertFalse(DebugKit.version.isStable)
    }
    var log:String {
        do {
            let stderr = try String(contentsOfFile: path)
            return stderr
        } catch {
            fatalError()
        }
    }
    func test_readme_1() throws {
        dbg(to: handle, .info, "All good") // sends "debug-info: All good" to stderr
        dbg(to: handle, .error, "Bang!") // sends "debug-error: Bang!" to stderr
        XCTAssertEqual(log,
                            """
                            debug-info: All good
                            debug-error: Bang!
                            
                            """
        )
        //print(#function, self.stack)
    }
    func test_readme_2() {
        
        func someFunction(debug mask:DebugTopicSet) {
            // sends "debug-error: File not found" to stderr when .error is included in the mask
            dbg(to: handle, .error, mask, "File not found")
        }
        
        let mask:DebugTopicSet = [.info, .error]
        // results into "debug-error: File not found" to be sent to stderr
        someFunction(debug: mask)
        XCTAssertEqual(log,
                            """
                            debug-error: File not found
                            
                            """
        )
    }
    func test_readme_3() {
        
        //let handle = FileHandle.standardOutput
        let mask:DebugTopicSet = [.info, .warning]
        dbg(to: handle, .warning, mask, "visible") // sends "debug-warning: visible" to stdout
        dbg(to: handle, .error, mask, "not visible") // doesn't send anything to stdout
        XCTAssertEqual(log,
                            """
                            debug-warning: visible
                            
                            """
        )
        
    }
    func test_readme_4() {
        dbg(to: handle, .critical, "Bang!") // sends "debug-4: Bang!" to stderr
        XCTAssertEqual(log,
                            """
                            debug-4: Bang!
                            
                            """
        )
    }
    func test_readme_5() {
        // all
        dbg(to: handle, [.info, .warning, .error], [.all], "topic is active")
        // warning
        dbg(to: handle, [.info, .warning, .error], [.warning], "topic is active")
        // unconditional -> all
        dbg(to: handle, [.info, .warning, .error], "topic is active")
        XCTAssertEqual(log,
                            """
                            debug-info: topic is active
                            debug-warning: topic is active
                            debug-error: topic is active
                            debug-warning: topic is active
                            debug-info: topic is active
                            debug-warning: topic is active
                            debug-error: topic is active
                            
                            """
        )
    }
    func test_readme_6() {
        dbg(to:handle, .telemetry, prefix: "myappname", labelSeparator: "_", messageSeparator: "; ", terminator: " ✓\n", "start") // sends "myappname_telemetry; start ✓" to stderr
        
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
        
        appdbg(to: handle, .telemetry, [.all], "start") // sends "myappname_telemetry; start ✓" to stderr
        XCTAssertEqual(log,
                            """
                            myappname_telemetry; start ✓
                            myappname_telemetry; start ✓
                            
                            """
        )
    }
    func test_readme_7() {
        let mask:DebugTopicSet = [.all]
        
        _ = mask.contains(.info) // evaluates true
        _ = mask.contains(.all) // evaluates true
        _ = mask.contains(DebugTopic(level: 42)) // evaluates true
        
        XCTAssertTrue(mask.contains(.info)) // evaluates true
        XCTAssertTrue(mask.contains(.all))  // evaluates true
        XCTAssertTrue(mask.contains(DebugTopic(level: 42))) // evaluates true
    }
    func test_timestamped() {
        let d = Date(timeIntervalSince1970: 1_000_000_000)
        dbg(to: handle, .info, [.all], prefix: "\(d)", labelSeparator: ":", "Timestamped debug entry.")
        XCTAssertEqual(log,
                            """
                            2001-09-09 01:46:40 +0000:info: Timestamped debug entry.
                            
                            """
        )
    }
    func test_formatting() {
        let tests:[((DebugTopic, String, String?, String?, String?, String), String)] = [
            ((.info, "debug", nil, nil, nil, "kala"), "debugkala"),
            ((.info, "debug", nil, nil, "\n", "kala"), "debugkala\n"),
            ((.info, "DBG", nil, nil, "\n", "kala"), "DBGkala\n"),
            ((.info, "", nil, nil, "\n", "kala"), "kala\n"),
            ((.critical, "debug", nil, nil, "\n", "kala"), "debugkala\n"),
            ((.critical, "debug", "-", nil, "\n", "kala"), "debug-4kala\n"),
            ((.info, "debug", "-", nil, "\n", "kala"), "debug-infokala\n"),
            ((.info, "debug", "-", ">", "\n", "kala"), "debug-info>kala\n"),
            ((.info, "debug", nil, ">", "\n", "kala"), "debug>kala\n"),
            ((.critical, "debug", nil, ">", "\n", "kala"), "debug>kala\n"),
            ((.critical, "", nil, nil, "\n", "kala"), "kala\n"),
            ((.info, "debug", "_", ":", "[EOF]\n", "kala"), "debug_info:kala[EOF]\n"),
        ]
        var acc = ""
        for ((topic, prefix, lsep, msep, term, msg),expected) in tests {
            dbg(to: handle, topic, prefix: prefix,
                labelSeparator: lsep, messageSeparator: msep, terminator: term,
                msg)
            acc += expected
        }
        dbg(to: handle, .info, "message")
        dbg(to: handle, .info, prefix: "dbg", "message")
        dbg(to: handle, .info, labelSeparator: "_", "message")
        dbg(to: handle, .info, messageSeparator: "->", "message")
        dbg(to: handle, .info, terminator: "⮐\n", "message")
        dbg(to: handle, .info, prefix: "dbg", labelSeparator: "_", "message")
        dbg(to: handle, .info, prefix: "dbg", messageSeparator: "->", "message")
        dbg(to: handle, .info, prefix: "dbg", labelSeparator: nil, messageSeparator: "->", "message")
        XCTAssertEqual(log, acc +
                            """
                            debug-info: message
                            dbg-info: message
                            debug_info: message
                            debug-info->message
                            debug-info: message⮐
                            dbg_info: message
                            dbg-info->message
                            dbg->message
                            
                            """
        )
    }
    func test_unleveled() {
        dbg(to: handle, "kala")
        dbg(to: handle, prefix: "dbg", "kala")
        dbg(to: handle, prefix: "dbg", messageSeparator: ">", "kala")
        XCTAssertEqual(log,
                            """
                            debug-all: kala
                            dbg-all: kala
                            dbg-all>kala
                            
                            """
        )
    }
    func test_unlabeled() {
        dbg(to: handle, .labeledEmpty, "ok")
        dbg(to: handle, .labeledEmpty, labelSeparator: nil, "ok")
        dbg(to: handle, .labeledEmpty, labelSeparator: "_", "ok")
        
        dbg(to: handle, .critical, "click")
        dbg(to: handle, .critical, messageSeparator: nil, "click")
        dbg(to: handle, .critical, messageSeparator: ">", "click")
        dbg(to: handle, .critical, labelSeparator: ":", "click")
        dbg(to: handle, .critical, labelSeparator: nil, "click")
        
        XCTAssertEqual(log,
                            """
                            debug-: ok
                            debug: ok
                            debug_: ok
                            debug-4: click
                            debug-4click
                            debug-4>click
                            debug:4: click
                            debug: click
                            
                            """
        )
    }
    
    func test_init_with_level() {
        //        let warning = DebugTopic(integerLiteral: 1)
        let warning = DebugTopic(level: 1)
        XCTAssertEqual(warning.level, 1)
        XCTAssertNil(warning.label)
        dbg(to: handle, 1, "Disk space low")
        dbg(to: handle, 9, "Getting hot here...")
        
        XCTAssertEqual(log,
                            """
                            debug-1: Disk space low
                            debug-9: Getting hot here...
                            
                            """
        )
    }
    func test_init_with_mask_array_literal() {
        //let handle = FileHandle.standardError
        dbg(to: handle, .warning, [.info, .warning], "visible")
        dbg(to: handle, .error, [.info, .warning], "not visible")
        dbg(to: handle, .info, [.info, .warning], "also visible")
        
        XCTAssertEqual(log,
                            """
                            debug-warning: visible
                            debug-info: also visible
                            
                            """
        )
    }
    func test_topic_all() {
        //let handle = FileHandle.standardError
        let infoMask = DebugTopicSet([.info])
        let allMask = DebugTopicSet([.all])
        if infoMask.contains(.info) {
            dbg(to: handle, .warning, "ok")
            dbg(to: handle, .error, "ok")
            dbg(to: handle, .info, "ok")
            dbg(to: handle, .all, "ok")
        }
        if infoMask.contains(.all) {
            dbg(to: handle, .warning, "test failed, if you see this")
            dbg(to: handle, .error, "test failed, if you see this")
            dbg(to: handle, .info, "test failed, if you see this")
            dbg(to: handle, .all, "test failed, if you see this")
        }
        if allMask.contains(.info) {
            dbg(to: handle, .warning, "ok")
            dbg(to: handle, .error, "ok")
            dbg(to: handle, .info, "ok")
            dbg(to: handle, .all, "ok")
        }
        if allMask.contains(.all) {
            dbg(to: handle, .warning, "ok")
            dbg(to: handle, .error, "ok")
            dbg(to: handle, .info, "ok")
            dbg(to: handle, .all, "ok")
        }
        
        XCTAssertEqual(log,
                            """
                            debug-warning: ok
                            debug-error: ok
                            debug-info: ok
                            debug-all: ok
                            debug-warning: ok
                            debug-error: ok
                            debug-info: ok
                            debug-all: ok
                            debug-warning: ok
                            debug-error: ok
                            debug-info: ok
                            debug-all: ok
                            
                            """
        )
        
    }
    func test_dlog_unleveled() {
        dlog(to: handle, "unleveled, timestamped")
        XCTAssertEqual(log.dropFirst(20), "unleveled, timestamped\n")
    }
    func test_dlog_leveled() {
        do {
            dlog(to: handle, [.info], "log entry")
            XCTAssertEqual(log.dropFirst(20), "[info]: log entry\n")
        }
    }
    func test_dlog_multileveled() {
        do {
            dlog(to: handle, [.info, .error], "log entry")
            let ee:[String] = [
                "[info]: log entry",
                "[error]: log entry",
            ]
            let arr:[String] = log.split(separator: "\n").map({ String($0) })
            for (e,ee) in zip(arr, ee) {
                let tail:String = String(e.dropFirst(20))
                XCTAssertEqual(tail, ee)
            }
        }
    }
}
final class DebugTopicTests: XCTestCase {
    func test_codable_debugtopic() throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(DebugTopic.telemetry)
            guard let s = String(data: encoded, encoding: .utf8) else {
                XCTFail()
                return
            }
            print(s)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DebugTopic.self, from: encoded)
            XCTAssertEqual(DebugTopic.telemetry, decoded)
        }
        do {
            let encoder = PropertyListEncoder()
            let encoded = try encoder.encode(DebugTopic.telemetry)
            let decoder = PropertyListDecoder()
            let decoded = try decoder.decode(DebugTopic.self, from: encoded)
            XCTAssertEqual(DebugTopic.telemetry, decoded)
        }
        do {
            let data = String(// expect to fail
                "{ \"level\" : 64, \"label\" : \"level out of bounds\" }"
            ).data(using: .utf8)!
            let decoder = JSONDecoder()
            let decoded = try? decoder.decode(DebugTopic.self, from: data)
            XCTAssertNil(decoded)
        }
        do {
            let data = String( // expect to fail
                "{ \"level\" : -1, \"label\" : \"level out of bounds\" }"
            ).data(using: .utf8)!
            let decoder = JSONDecoder()
            let decoded = try? decoder.decode(DebugTopic.self, from: data)
            XCTAssertNil(decoded)
        }
    }
}
final class DebugTopicSetTests: XCTestCase {
    func test_with_all_bit_values() {
        for i in 0..<MemoryLayout<DebugTopic.BitValueType>.size * 8 {
            let topic = DebugTopic(level: i, "a")
            XCTAssertEqual(topic.level, i)
            XCTAssertEqual(topic.label, "a")
        }
    }

    func test_codable_debugtopicset() throws {
        do {
            let set:DebugTopicSet = [.info, .warning, .error, .telemetry, .labeledEmpty]
            let topicSet = DebugTopicSet(set)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(topicSet)
            /*guard let s = String(data: encoded, encoding: .utf8) else {
             XCTFail()
             return
             }
             print(s)*/
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DebugTopicSet.self, from: encoded)
            XCTAssertEqual(set, decoded)
        }
        do {
            let set:DebugTopicSet = .catchAll
            let topicSet = DebugTopicSet(set)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(topicSet)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DebugTopicSet.self, from: encoded)
            XCTAssertEqual(set, decoded)
        }
    }
}
final class OneBitValueTests: XCTestCase {
    func test_zero_position_and_zero() {
        do {
            let zero = OneBitValue<UInt8>()
            XCTAssertTrue(zero.isZero)
            XCTAssertEqual(zero.position, 8)
        }
        do {
            let zero = OneBitValue<UInt32>.zero
            XCTAssertTrue(zero.isZero)
            XCTAssertEqual(zero.position, 32)
        }
        do {
            let zero = OneBitValue<Int64>()
            XCTAssertTrue(zero.isZero)
            XCTAssertEqual(zero.position, 64)
        }
    }
    func test_singlebitvalue() throws {
        for i in 0..<MemoryLayout<DebugTopic.BitValueType>.size * 8 {
            let bitvalue = OneBitValue<DebugTopic.BitValueType>(position: i)
            XCTAssertEqual(bitvalue?.position, i)
        }
    }
    func test_codable_singlebitvalue() throws {
        do {
            let encoder = JSONEncoder()
            let bv = OneBitValue<Int8>(position: 4)!
            let encoded = try encoder.encode(bv)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(OneBitValue<Int8>.self, from: encoded)
            XCTAssertEqual(bv, decoded)
        }
        do {
            let data = String(
                "{ \"value\" : -1 }" // expect to fail
            ).data(using: .utf8)!
            let decoder = JSONDecoder()
            let decoded = try? decoder.decode(DebugTopic.self, from: data)
            XCTAssertNil(decoded)
        }
        do {
            let data = String(
                "{ \"value\" : 8 }" // expect to fail
            ).data(using: .utf8)!
            let decoder = JSONDecoder()
            let decoded = try? decoder.decode(DebugTopic.self, from: data)
            XCTAssertNil(decoded)
        }
        do {
            for i in 0..<MemoryLayout<DebugTopic.BitValueType>.size * 8 {
                let bitvalue = OneBitValue<DebugTopic.BitValueType>(position: i)
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let encoded = try encoder.encode(bitvalue)
                    /*guard let s = String(data: encoded, encoding: .utf8) else {
                     XCTFail()
                     return
                     }
                     print(s)*/
                    let decoder = JSONDecoder()
                    let decoded = try decoder.decode(OneBitValue<DebugTopic.BitValueType>.self, from: encoded)
                    XCTAssertEqual(bitvalue, decoded)
                }
                do {
                    let encoder = PropertyListEncoder()
                    let encoded = try encoder.encode(bitvalue)
                    let decoder = PropertyListDecoder()
                    let decoded = try decoder.decode(OneBitValue<DebugTopic.BitValueType>.self, from: encoded)
                    XCTAssertEqual(bitvalue, decoded)
                }
            }
        }
    }
}
