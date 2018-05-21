//
//  URLMappingTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore

class URLMappingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Flint.resetForTesting()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testURLPatterns() {
        let fixtures: [(pattern: String, incomingURLPath: String, expectedParams: [String:String]?)] = [
            (pattern: "/hello/", incomingURLPath: "/hello", expectedParams: nil),
            (pattern: "/hello", incomingURLPath: "/hello", expectedParams: [:]),
            (pattern: "/^hello", incomingURLPath: "/^hello", expectedParams: [:]),
            (pattern: "/hello/$(value)", incomingURLPath: "/hello/$someValueWithDollar", expectedParams: ["value":"$someValueWithDollar"]),
            (pattern: "/hello/world", incomingURLPath: "/hello", expectedParams: nil),
            (pattern: "/hello/world", incomingURLPath: "/hello/", expectedParams: nil),
            (pattern: "/hello/world", incomingURLPath: "/hello/worl", expectedParams: nil),
            (pattern: "/hello/world", incomingURLPath: "hello/world", expectedParams: nil),
            (pattern: "/hello/world", incomingURLPath: "/hello/world", expectedParams: [:]),
            (pattern: "/hello/**", incomingURLPath: "/hello", expectedParams: nil),
            (pattern: "/hello/**", incomingURLPath: "/hello/", expectedParams: [:]),
            (pattern: "/hello/**", incomingURLPath: "/hello/this/is/a/test", expectedParams: [:]),
            (pattern: "/hello/*", incomingURLPath: "/hello/small/world", expectedParams: nil),
            (pattern: "/hello/*", incomingURLPath: "/hello/small", expectedParams: [:]),
            (pattern: "/hello/*", incomingURLPath: "/hello/small/", expectedParams: nil),
            (pattern: "/hello/*/", incomingURLPath: "/hello/small/", expectedParams: [:]),
            (pattern: "/hello/*/world", incomingURLPath: "/hello/small/world", expectedParams: [:]),
            (pattern: "/$(param1)/world", incomingURLPath: "/hello/world", expectedParams: ["param1":"hello"]),
            (pattern: "/prefix$(param1)/world", incomingURLPath: "/prefixhello/world", expectedParams: ["param1":"hello"]),
            (pattern: "/$(param1)suffix/world", incomingURLPath: "/hellosuffix/world", expectedParams: ["param1":"hello"]),
            (pattern: "/prefix$(param1)suffix/world", incomingURLPath: "/prefixhellosuffix/world", expectedParams: ["param1":"hello"]),
            (pattern: "/prefix$(param1)suffix/world", incomingURLPath: "/prefixhellosuffix/", expectedParams: nil),
            (pattern: "/prefix$(param1)suffix/world", incomingURLPath: "/prefixhellosuf/world", expectedParams: nil),
            (pattern: "/documents/prefix$(param1)suffix/world", incomingURLPath: "/prefixhellosuf/world", expectedParams: nil),
            (pattern: "/documents/prefix$(param1)suffix/world", incomingURLPath: "/documents/prefixhellosuffix/world", expectedParams: ["param1":"hello"]),
            (pattern: "/documents/prefix$(param1)suffix/$(thing)", incomingURLPath: "/documents/prefixhellosuffix/world", expectedParams: ["param1":"hello", "thing":"world"]),
            (pattern: "/documents/prefix$(param1)suffix/world/$(mode)", incomingURLPath: "/documents/prefixhellosuffix/world/map", expectedParams: ["param1":"hello", "mode":"map"]),
        ]
        
        fixtures.forEach {
            let pattern = RegexURLPattern(urlPattern: $0.pattern)
            print("Testing pattern: \($0.pattern) for URL: \($0.incomingURLPath), expecting: \(String(describing: $0.expectedParams))")
            switch pattern.match(path: $0.incomingURLPath) {
                case .none:
                    XCTAssertNil($0.expectedParams, "Testing pattern: \($0.pattern) for URL: \($0.incomingURLPath), expecting: \(String(describing: $0.expectedParams))")
                case .some(let params):
                    XCTAssertEqual($0.expectedParams, params, "Testing pattern: \($0.pattern) for URL: \($0.incomingURLPath), expecting: \(String(describing: $0.expectedParams))")
            }
            
        }
    }

    func testCreatingURLsFromPatterns() {
        let fixtures: [(pattern: String, parameters: [String:String]?, expectedPath: String?)] = [
            (pattern: "/hello/", parameters: nil, expectedPath: "/hello/"),
            (pattern: "/hello", parameters: nil, expectedPath: "/hello"),
            (pattern: "/hello/world", parameters: nil, expectedPath: "/hello/world"),
            (pattern: "/hello/world", parameters: ["x":"y"], expectedPath: "/hello/world"),
            (pattern: "/hello/**", parameters: nil, expectedPath: "/hello/"),
            (pattern: "/hello/*", parameters: nil, expectedPath: nil),
            (pattern: "/hello/*/", parameters: nil, expectedPath: nil),
            (pattern: "/hello/*/world", parameters: nil, expectedPath: nil),
            (pattern: "/$(param1)/world", parameters: nil, expectedPath: nil),
            (pattern: "/$(param1)/world", parameters: ["x":"y"], expectedPath: nil),
            (pattern: "/$(param1)/world", parameters: ["param1":"hello"], expectedPath: "/hello/world"),
            (pattern: "/prefix$(param1)/world", parameters: ["param1":"hello"], expectedPath: "/prefixhello/world"),
            (pattern: "/$(param1)suffix/world", parameters: ["param1":"hello"], expectedPath: "/hellosuffix/world"),
            (pattern: "/prefix$(param1)suffix/world", parameters: ["param1":"hello"], expectedPath: "/prefixhellosuffix/world"),
            (pattern: "/prefix$(param1)suffix/world", parameters: ["param3":"hello"], expectedPath: nil),
            (pattern: "/documents/prefix$(param1)suffix/world", parameters: ["param1":"hello"], expectedPath: "/documents/prefixhellosuffix/world"),
            (pattern: "/documents/prefix$(param1)suffix/$(thing)", parameters: ["param1":"hello", "thing":"testing"], expectedPath: "/documents/prefixhellosuffix/testing"),
            (pattern: "/documents/prefix$(param1)suffix/$(thing)", parameters: ["param1":"hello", "xthing":"testing"], expectedPath: nil),
            (pattern: "/documents/prefix$(param1)suffix/world/$(mode)", parameters: ["param1":"hello", "xmode":"map"], expectedPath: nil),
            (pattern: "/documents/prefix$(param1)suffix/world/$(mode)", parameters: ["param1":"hello", "mode":"map"], expectedPath: "/documents/prefixhellosuffix/world/map"),
        ]
        
        fixtures.forEach {
            let pattern = RegexURLPattern(urlPattern: $0.pattern)
            print("Testing pattern: \($0.pattern) with params: \(String(describing: $0.parameters)), expecting: \(String(describing: $0.expectedPath))")
            if pattern.isValidForLinkCreation {
                if let path = pattern.buildPath(with: $0.parameters) {
                    XCTAssertEqual(path, $0.expectedPath, "With pattern: \($0.pattern) with params: \(String(describing: $0.parameters)), expected: \(String(describing: $0.expectedPath))")
                } else {
                    XCTAssertNil($0.expectedPath, "Expected \($0.expectedPath ?? "<nil>") for \($0.pattern) but received nil")
                }
            } else {
                XCTAssertNil($0.expectedPath, "Expected \($0.pattern) to be link creation compatible but it isn't")
            }
        }
    }
}

