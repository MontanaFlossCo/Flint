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
#if canImport(Network) && os(iOS)
        let expectedCount = 1
#else
        let expectedCount = 2
#endif
        XCTAssertEqual(dummyFeatureMetadata.actions.count, expectedCount, "Actions not bound")
    }
}
