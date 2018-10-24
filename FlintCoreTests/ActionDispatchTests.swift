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
        let completionQueue = SmartDispatchQueue(queue: DispatchQueue.global(), owner: "testqueue" as AnyObject)
        
        let completionExpectation = expectation(description: "Async completion called")
        let completion = Action.Completion(completionHandler: { outcome, callAsync in
            XCTAssertTrue(callAsync, "Completion was not called async")
            XCTAssertTrue(completionQueue.isCurrentQueue, "Completion not called on the expected queue")
            completionExpectation.fulfill()
        })
        completion.completionQueue = completionQueue
        
        let result = dispatcher.perform(request: request, completion: completion)
        XCTAssertTrue(result.isCompletingAsync, "Expected to complete async")

        waitForExpectations(timeout: 5, handler: nil)
    }

}

fileprivate protocol AsyncTestPresenter {
    func asyncActionWasCalled()
}

fileprivate final class AsyncTestAction: UIAction {
    typealias PresenterType = AsyncTestPresenter

    static func perform(context: ActionContext<NoInput>, presenter: AsyncTestPresenter, completion: Completion) -> Completion.Status {
        let asyncStatus = completion.willCompleteAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            asyncStatus.completed(.successWithFeatureTermination)
        })
        return asyncStatus
    }
}

fileprivate final class AsyncTestFeature: Feature {
    static var description: String = "Testing"
    
    static let asyncTest = action(AsyncTestAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
    }
}

fileprivate class MockAsyncTestPresenter: AsyncTestPresenter {
    var called = false
    
    func asyncActionWasCalled() {
        called = true
    }
}
