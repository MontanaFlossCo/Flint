//
//  FlintTests.swift
//  FlintTests
//
//  Created by Marc Palmer on 09/10/2017.
//  Copyright © 2017 Montana Floss Co. All rights reserved.
//

import XCTest
@testable import FlintCore

class FlintTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        Flint.resetForTesting()
    }
    
    // MARK: Test artifacts
    
    func testFeatureMetadata() {
        Flint.register(group: DummyFeatures.self)
        XCTAssertEqual(Flint.allFeatures.count, 2, "Two features should be registered")
        
        guard let dummyFeatureMetadata = Flint.metadata(for: DummyFeature.self) else {
            XCTFail("Missing metadata")
            return
        }
        let expectedCount: Int
#if canImport(Network) && os(iOS)
        if #available(iOS 12, *) {
            expectedCount = 2
        } else {
            expectedCount = 1
        }
#else
        expectedCount = 1
#endif
        XCTAssertEqual(dummyFeatureMetadata.actions.count, expectedCount, "Actions not bound")
    }
}
