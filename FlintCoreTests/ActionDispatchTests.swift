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

    func testSyncCompletingAction() {
        let dispatcher = DefaultActionDispatcher()
        let presenter = MockPresenter()
        
        let request = ActionRequest(
            uniqueID: 0,
            userInitiated: false,
            source: .application,
            session: .main,
            actionBinding: TestFeature.syncTest,
            input: .noInput,
            presenter: presenter,
            logContextCreator: { _, _, _ in
                return LogEventContext.mockContext()
            }
        )

        request.setLoggingSessionDetailsCreator { () -> (sessionID: String, activitySequenceID: String) in
            return ("test-session-id", "test-activity")
        }
        
        let completionExpectation = expectation(description: "Sync completion called")
        let queue = SmartDispatchQueue(queue: DispatchQueue.main)
        let completion = Action.Completion(smartQueue: queue, completionHandler: { outcome, callAsync in
            XCTAssertTrue(!callAsync, "Completion was not called sync")
            XCTAssertTrue(queue.isCurrentQueue, "Completion not called on the expected queue")
            completionExpectation.fulfill()
        })
        
        let result = dispatcher.perform(request: request, completion: completion)
        XCTAssertTrue(!result.isCompletingAsync, "Expected to complete sync")

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testAsyncCompletingAction() {
        let dispatcher = DefaultActionDispatcher()
        let presenter = MockPresenter()
        
        let request = ActionRequest(
            uniqueID: 0,
            userInitiated: false,
            source: .application,
            session: .main,
            actionBinding: TestFeature.asyncTest,
            input: .noInput,
            presenter: presenter,
            logContextCreator: { _, _, _ in
                return LogEventContext.mockContext()
            }
        )

        request.setLoggingSessionDetailsCreator { () -> (sessionID: String, activitySequenceID: String) in
            return ("test-session-id", "test-activity")
        }
        
        let completionExpectation = expectation(description: "Async completion called")
        let queue = SmartDispatchQueue(queue: DispatchQueue.global())
        let completion = Action.Completion(smartQueue: queue, completionHandler: { outcome, callAsync in
            XCTAssertTrue(callAsync, "Completion was not called async")
            XCTAssertTrue(queue.isCurrentQueue, "Completion not called on the expected queue")
            completionExpectation.fulfill()
        })
        
        let result = dispatcher.perform(request: request, completion: completion)
        XCTAssertTrue(result.isCompletingAsync, "Expected to complete async")

        waitForExpectations(timeout: 5, handler: nil)
    }

}

fileprivate final class AsyncTestAction: UIAction {
    typealias PresenterType = MockPresenter

    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        let asyncStatus = completion.willCompleteAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            asyncStatus.completed(.successWithFeatureTermination)
        })
        return asyncStatus
    }
}

fileprivate final class SyncTestAction: UIAction {
    typealias PresenterType = MockPresenter

    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        presenter.actionWasCalled()
        return completion.completedSync(.success)
    }
}

fileprivate final class TestFeature: Feature {
    static var description: String = "Testing"
    
    static let asyncTest = action(AsyncTestAction.self)
    static let syncTest = action(SyncTestAction.self)

    static func prepare(actions: FeatureActionsBuilder) {
    }
}
