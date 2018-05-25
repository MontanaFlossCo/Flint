//
//  FeaturesTests.swift
//  FeaturesTests
//
//  Created by Marc Palmer on 09/10/2017.
//  Copyright © 2017 Montana Floss Co. All rights reserved.
//

import XCTest
@testable import FlintCore

class FlintCoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        Flint.resetForTesting()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: Test artifacts
    
    func testFeatureMetadata() {
        Flint.register(DummyFeatures.self)
        XCTAssertEqual(Flint.allFeatures.count, 2, "Two features should be registered")
        
        guard let dummyFeatureMetadata = Flint.metadata(for: DummyStaticFeature.self) else {
            XCTFail("Missing metadata")
            return
        }
        XCTAssertEqual(dummyFeatureMetadata.actions.count, 1, "Actions not bound")
    }
}
