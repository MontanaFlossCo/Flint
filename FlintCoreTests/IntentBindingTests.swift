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

    /// Verify that action metadata includes the Intent if any for intent actions
    func testIntentMetadataBinding() {
        guard let metadata = Flint.metadata(for: DummyFeature.self) else {
            fatalError("Expected metadata for test feature")
        }
        guard let actionMetadata = metadata.actionMetadata(action: DummyFeature.intentAction.action) else {
            fatalError("Expected metadata for test action")
        }
        let intentTypeName = String(reflecting: DummyIntent.self)
        XCTAssertEqual(actionMetadata.intentTypeName, intentTypeName, "Intent type was not found in action metadata")
    }

    @available(iOS 12, *)
    func testPerformIntent() {
        let intent = DummyIntent()
        let presenter = IntentResponsePresenter(completion: { (DummyIntentResponse) in
            
        })
        let result = DummyFeature.intentAction.perform(intent: intent, presenter: presenter)
        XCTAssert(result == .success)
    }
}
