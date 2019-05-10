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

        Flint.quickSetup(TestFeatures.self, domains: [], initialDebugLogLevel: .off, initialProductionLogLevel: .off)
    }
    
    /// Verify that calling an action that must be called on the main queue, completes when called
    /// from the main queue.
    func testMainQueueSyncActionFromMainQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Sync completion called")
        ActionSession.main.perform(TestFeatures.syncMainThreadAction,
                                   input: .noInput,
                                   presenter: presenter,
                                   completion: { (outcome: ActionOutcome) in
            XCTAssert(outcome == .success, "Action should have completed successfully")
            completionExpectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }

    /// Test that calling a main-queue action asynchronously on another queue works.
    func testMainQueueSyncActionFromNonMainQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Sync completion called")
        DispatchQueue.global(qos: .background).async {
            ActionSession.main.perform(TestFeatures.syncMainThreadAction,
                                       input: .noInput,
                                       presenter: presenter,
                                       completion: { (outcome: ActionOutcome) in
                XCTAssert(outcome == .success, "Action should have completed successfully")
                completionExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }

    /// Verify that calling an action that must be called on a background queue, completes when called
    /// from the main queue.
    func testBackgroundQueueSyncActionFromMainQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Sync completion called")
        ActionSession.main.perform(TestFeatures.syncBackgroundThreadAction,
                                           input: .noInput,
                                           presenter: presenter,
                                           completion: { (outcome: ActionOutcome) in
            XCTAssert(outcome == .success, "Action should have completed successfully")
            completionExpectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }

    /// Verify that calling an action that must be called on a background queue, completes when called
    /// from the correct background queue.
    func testBackgroundQueueSyncActionFromBackgroundQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Sync completion called")
        SyncBackgroundThreadAction.queue.async {
            Sessions.backgroundSession.perform(TestFeatures.syncBackgroundThreadAction,
                                               input: .noInput,
                                               presenter: presenter,
                                               completion: { (outcome: ActionOutcome) in
                XCTAssert(outcome == .success, "Action should have completed successfully")
                completionExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }
 
    /// Verify that calling an action that must be called on the main queue and completes asynchronously does so when called
    /// from the main queue.
    func testMainQueueAsyncCompletingActionFromMainQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Async completion called")
        ActionSession.main.perform(TestFeatures.asyncCompletingMainThreadAction,
                                   input: .noInput,
                                   presenter: presenter,
                                   completion: { (outcome: ActionOutcome) in
            XCTAssert(outcome == .success, "Action should have completed successfully")
            completionExpectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }

    /// Verify that calling an action that must be called on the main queue and completes asynchronously does so when called
    /// from the a background queue.
    func testMainQueueAsyncCompletingActionFromBackgroundQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Async completion called")
        DispatchQueue.global(qos: .background).async {
            ActionSession.main.perform(TestFeatures.asyncCompletingMainThreadAction,
                                       input: .noInput,
                                       presenter: presenter,
                                       completion: { (outcome: ActionOutcome) in
                XCTAssert(outcome == .success, "Action should have completed successfully")
                completionExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }

    /// Verify that calling an action that must be called on a non-main queue and completes asynchronously does so when called
    /// from the main queue.
    func testBackgroundQueueAsyncCompletingActionFromMainQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Async completion called")
        Sessions.backgroundSession.perform(TestFeatures.asyncCompletingBackgroundThreadAction,
                                           input: .noInput,
                                           presenter: presenter,
                                           completion: { (outcome: ActionOutcome) in
            XCTAssert(outcome == .success, "Action should have completed successfully")
            completionExpectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }
    
    /// Verify that calling an action that must be called on a non-main queue and completes asynchronously does so when called
    /// from the background queue.
    func testBackgroundQueueAsyncCompletingActionFromBackgroundQueue() {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        
        let completionExpectation = expectation(description: "Async completion called")
        SyncBackgroundThreadAction.queue.async {
            Sessions.backgroundSession.perform(TestFeatures.asyncCompletingBackgroundThreadAction,
                                               input: .noInput,
                                               presenter: presenter,
                                               completion: { (outcome: ActionOutcome) in
                XCTAssert(outcome == .success, "Action should have completed successfully")
                completionExpectation.fulfill()
            })
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }
}

// MARK: Helper Types

fileprivate class MockPresenter {
    var called = false
    
    func actionWorkWasDone() {
        called = true
    }
}

enum Sessions {
    static let backgroundSession = ActionSession.init(named: "background", userInitiatedActions: true)
}

fileprivate final class AsyncCompletingMainThreadAction: UIAction {
    typealias PresenterType = MockPresenter

    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        
        let asyncResult = completion.willCompleteAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            presenter.actionWorkWasDone()
            asyncResult.completed(.success)
        }
        
        return asyncResult
    }
}

fileprivate final class AsyncCompletingBackgroundThreadAction: UIAction {
    static var queue: DispatchQueue = DispatchQueue(label: "SyncBackgroundThreadAction")
    static var defaultSession: ActionSession? = Sessions.backgroundSession

    typealias PresenterType = MockPresenter

    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        
        let asyncResult = completion.willCompleteAsync()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            presenter.actionWorkWasDone()
            asyncResult.completed(.success)
        }
        
        return asyncResult
    }
}

fileprivate final class SyncMainThreadAction: UIAction {
    typealias PresenterType = MockPresenter

    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        presenter.actionWorkWasDone()
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class SyncBackgroundThreadAction: Action {
    static var queue: DispatchQueue = DispatchQueue(label: "SyncBackgroundThreadAction")
    static var defaultSession: ActionSession? = Sessions.backgroundSession

    typealias PresenterType = MockPresenter

    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        presenter.actionWorkWasDone()
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class TestFeatures: Feature, FeatureGroup {
    static var subfeatures: [FeatureDefinition.Type] = []
    
    static var description: String = "Test Features"
    
    static let syncMainThreadAction = action(SyncMainThreadAction.self)
    static let asyncCompletingMainThreadAction = action(AsyncCompletingMainThreadAction.self)
    static let syncBackgroundThreadAction = action(SyncBackgroundThreadAction.self)
    static let asyncCompletingBackgroundThreadAction = action(AsyncCompletingBackgroundThreadAction.self)

    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(syncMainThreadAction)
        actions.declare(asyncCompletingMainThreadAction)
        actions.declare(syncBackgroundThreadAction)
        actions.declare(asyncCompletingBackgroundThreadAction)
    }
}
