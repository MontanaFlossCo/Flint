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
        XCTAssertEqual(dummyFeatureMetadata.actions.count, 2, "Actions not bound")
    }
}
