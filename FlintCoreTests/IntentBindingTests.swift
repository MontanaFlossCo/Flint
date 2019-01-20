//
//  IntentBindingTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 05/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore

class IntentBindingTests: XCTestCase {

    override func setUp() {
        Flint.resetForTesting()
        Flint.quickSetup(DummyFeatures.self)
    }

    override func tearDown() {
    }

#if canImport(Network) && os(iOS)
    /// Verify that action metadata includes the Intent if any for intent actions
    func testIntentMetadataBinding() {
        if #available(iOS 12, *) {
            guard let metadata = Flint.metadata(for: DummyFeature.intentAction) else {
                fatalError("Expected metadata for test action binding")
            }
            let intentTypeName = String(reflecting: DummyIntent.self)
            XCTAssertEqual(metadata.intentTypeName, intentTypeName, "Intent type was not found in action metadata")
        }
    }

    func testPerformIntent() {
        if #available(iOS 12, *) {
            let intent = DummyIntent()
            let presenter = IntentResponsePresenter(completion: { (DummyIntentResponse) in
                
            })
            let result = DummyFeature.intentAction.perform(intent: intent, presenter: presenter)
            XCTAssert(result == .success)
        }
    }
#endif

}
