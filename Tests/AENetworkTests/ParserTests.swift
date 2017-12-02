//
//  ParserTests.swift
//  AENetwork
//
//  Created by Marko Tadić on 12/2/17.
//

import XCTest
@testable import AENetwork

class ParserTests: XCTestCase {

    let parser = Parser()

    func testParsingDictionary() {
        let dict = ["hello" : "world"]
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            let parsed = try parser.jsonDictionary(from: data)
            XCTAssertEqual(parsed["hello"] as? String, "world")
        } catch {
            XCTAssert(false, "Should be able to parse dictionary from JSON data.")
        }
    }

    func testParsingArray() {
        let array = ["hello", "world"]
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
            let parsed = try parser.jsonArray(from: data)
            XCTAssertEqual(parsed.last as? String, "world")
        } catch {
            XCTAssert(false, "Should be able to parse array from JSON data.")
        }
    }

    func testParsingError() {
        let dict = ["hello" : "world"]
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            let _ = try parser.jsonArray(from: data)
        } catch {
            let test = error is Parser.ParserError
            XCTAssert(test, "Should throw \(error) when parsing JSON data of wrong type.")
        }
    }

    static var allTests : [(String, (ParserTests) -> () throws -> Void)] {
        return [
            ("testParsingDictionary", testParsingDictionary),
            ("testParsingArray", testParsingArray),
            ("testParsingError", testParsingError)
        ]
    }

}
