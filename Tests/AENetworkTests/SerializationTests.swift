/**
 *  https://github.com/tadija/AENetwork
 *  Copyright (c) Marko Tadić 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
@testable import AENetwork

class SerializationTests: XCTestCase {

    // MARK: Tests

    func testSerializingJsonDataToDictionary() {
        let dict = ["hello" : "world"]
        do {
            let data = try Data(jsonWith: dict)
            let parsed = try data.toDictionary()
            XCTAssertEqual(parsed["hello"] as? String, "world")
        } catch {
            XCTAssert(false, "Should be able to serialize dictionary from JSON data.")
        }
    }

    func testSerializingJsonDataToArray() {
        let array = ["hello", "world"]
        do {
            let data = try Data(jsonWith: array)
            let parsed = try data.toArray()
            XCTAssertEqual(parsed.last as? String, "world")
        } catch {
            XCTAssert(false, "Should be able to serialize array from JSON data.")
        }
    }

    func testSerializationError() {
        let dict = ["hello" : "world"]
        do {
            let data = try Data(jsonWith: dict)
            let _ = try data.toArray()
        } catch {
            let test = error is Data.SerializationError
            XCTAssert(test, "Should throw \(error) when serializing JSON data to the wrong type.")
        }
    }

    static var allTests : [(String, (SerializationTests) -> () throws -> Void)] {
        return [
            ("testSerializingJsonDataToDictionary", testSerializingJsonDataToDictionary),
            ("testSerializingJsonDataToArray", testSerializingJsonDataToArray),
            ("testSerializationError", testSerializationError)
        ]
    }

}
