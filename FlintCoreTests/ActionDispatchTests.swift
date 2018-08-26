//
//  ActionDispatchTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import XCTest
@testable import FlintCore

class ActionDispatchTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testAsyncCompletingAction() {
        let dispatcher = DefaultActionDispatcher()
        let presenter = MockAsyncTestPresenter()
        
        let request = ActionRequest(
            uniqueID: 0,
            userInitiated: false,
            source: .application,
            session: ActionSession.main,
            actionBinding: AsyncTestFeature.asyncTest,
            input: NoInput.none,
            presenter: presenter,
            logContextCreator: { _, _ in
                return LogEventContext.mockContext()
            }
        )

        request.setLoggingSessionDetailsCreator { () -> (sessionID: String, activitySequenceID: String) in
            return ("test-session-id", "test-activity")
        }
        let queue = SmartDispatchQueue(queue: AsyncTestAction.queue, owner: "testqueue" as AnyObject)
        
        let completionExpectation = expectation(description: "Async completion called")
        let completion = Action.Completion(completionHandler: { outcome, callAsync in
            completionExpectation.fulfill()
        })
        
        let result = dispatcher.perform(request: request, callerQueue: queue, completion: completion)
        XCTAssertTrue(result.isCompletingAsync, "Expected to complete async")

        waitForExpectations(timeout: 5, handler: nil)
    }
}

protocol AsyncTestPresenter {
    func asyncActionWasCalled()
}

private final class AsyncTestAction: Action {
    typealias PresenterType = AsyncTestPresenter

    static func perform(context: ActionContext<NoInput>, presenter: AsyncTestPresenter, completion: Completion) -> Completion.Status {
        let asyncStatus = completion.willCompleteAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            asyncStatus.completed(.success(closeActionStack: true))
        })
        return asyncStatus
    }
}

private final class AsyncTestFeature: Feature {
    static var description: String = "Testing"
    
    static let asyncTest = action(AsyncTestAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

class MockAsyncTestPresenter: AsyncTestPresenter {
    var called = false
    
    func asyncActionWasCalled() {
        called = true
    }
}
