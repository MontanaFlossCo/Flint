//
//  ActionSessionTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
import FlintCore

class ActionSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Flint.resetForTesting()
    }
    
    func testAsyncActionPerformingSyncActionWithSimplifiedAPI() {
        Flint.quickSetup(TestFeature.self, domains: [], initialDebugLogLevel: .none, initialProductionLogLevel: .none)
        
        let presenter = MockTestPresenter()
        
        let completionExpectation = expectation(description: "Async completion called")
        TestFeature.action1.perform(presenter: presenter) { outcome in
            completionExpectation.fulfill()
            
            XCTAssertTrue(presenter.action1Called, "Action 1 should have been called")
            XCTAssertTrue(presenter.action2Called, "Action 2 should have been called")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}

fileprivate protocol Action2Presenter {
    func action2WasCalled()
}

fileprivate protocol Action1Presenter: Action2Presenter {
    func action1WasCalled()
}

fileprivate final class TestAction1: UIAction {
    typealias PresenterType = Action1Presenter

    static func perform(context: ActionContext<NoInput>, presenter: Action1Presenter, completion: Completion) -> Completion.Status {
        var syncOutcome: ActionOutcome?

        presenter.action1WasCalled()
        
        /// This is threadsafe if the ActionSessions' callerQueue is the same as this action's caller queue.
        /// It would be nice if we could protect against this not being the case
        TestFeature.action2.perform(presenter: presenter) { outcome in
            presenter.action2WasCalled()
            syncOutcome = outcome
        }

        guard let outcome = syncOutcome else {
            XCTFail("The second action must complete synchronously when using this API")
            return completion.willCompleteAsync()
        }
        
        switch outcome {
            case .failure(let error): return completion.completedSync(.failureWithFeatureTermination(error: error))
            case .success: return completion.completedSync(.successWithFeatureTermination)
        }
    }
}

fileprivate final class TestAction2: UIAction {
    typealias PresenterType = Action2Presenter

    static func perform(context: ActionContext<NoInput>, presenter: Action2Presenter, completion: Completion) -> Completion.Status {
        presenter.action2WasCalled()
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class TestFeature: Feature, FeatureGroup {
    static var subfeatures: [FeatureDefinition.Type] = []
    
    static var description: String = "Testing"
    
    static let action1 = action(TestAction1.self)
    static let action2 = action(TestAction2.self)

    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(action1)
        actions.declare(action2)
    }
}

fileprivate class MockTestPresenter: Action1Presenter {
    var action1Called = false
    var action2Called = false

    func action1WasCalled() {
        action1Called = true
    }

    func action2WasCalled() {
        action2Called = true
    }
}
