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
    
    /// Verify that calling an action that must be called on a background queue, completes when called
    /// from the correct background queue.
    fileprivate func _testAction<ActionType>(_ actionBinding: StaticActionBinding<TestFeatures, ActionType>,
            session: ActionSession? = ActionType.defaultSession,
            callAsync: Bool, callOnQueue queue: DispatchQueue? = nil)
            where ActionType: Action, ActionType.InputType == NoInput, ActionType.PresenterType == MockPresenter {
        // Use the presenter to detect if the body of the action was actually called, to guard against the session
        // giving us completion without invoking the action
        let presenter = MockPresenter()
        let completionExpectation = expectation(description: "Sync completion called")
        
        let block = {
            (session ?? ActionSession.main).perform(actionBinding,
                                                    input: .noInput,
                                                    presenter: presenter,
                                                    completion: { (outcome: ActionOutcome) in
                XCTAssert(outcome == .success, "Action should have completed successfully")
                completionExpectation.fulfill()
            })
        }
        
        if let queueToUse = queue {
            if callAsync {
                queueToUse.async(execute: block)
            } else {
                queueToUse.sync(execute: block)
            }
        } else {
            precondition(!callAsync, "Cannot perform action asynchronously unless you specify the queue on which to do it")
            block()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(presenter.called, "Action was not performed")
    }
    
    /// Verify that calling an action that must be called on the main queue, completes when called
    /// from the main queue.
    func testMainQueueSyncActionFromMainQueue() {
        _testAction(TestFeatures.syncMainThreadAction,
                    session: ActionSession.main,
                    callAsync: false,
                    callOnQueue: nil)
    }

    /// Test that calling a main-queue action asynchronously on another queue works.
    func testMainQueueSyncActionFromNonMainQueue() {
        _testAction(TestFeatures.syncMainThreadAction,
                    session: ActionSession.main,
                    callAsync: true,
                    callOnQueue: DispatchQueue.global(qos: .background))
    }

    /// Verify that calling an action that must be called on a background queue, completes when called
    /// from the main queue.
    func testBackgroundQueueSyncActionFromMainQueue() {
        _testAction(TestFeatures.syncBackgroundThreadAction,
                    session: Sessions.backgroundSession,
                    callAsync: false,
                    callOnQueue: nil)
    }

    /// Verify that calling an action that must be called on a background queue, completes when called
    /// from the correct background queue.
    func testBackgroundQueueSyncActionFromBackgroundQueue() {
        _testAction(TestFeatures.syncBackgroundThreadAction,
                    session: Sessions.backgroundSession,
                    callAsync: true,
                    callOnQueue: SyncBackgroundThreadAction.queue)
    }
 
    /// Verify that calling an action that must be called on the main queue and completes asynchronously does so when called
    /// from the main queue.
    func testMainQueueAsyncCompletingActionFromMainQueue() {
        _testAction(TestFeatures.asyncCompletingMainThreadAction,
                    session: .main,
                    callAsync: false,
                    callOnQueue: nil)
    }

    /// Verify that calling an action that must be called on the main queue and completes asynchronously does so when called
    /// from the a background queue.
    func testMainQueueAsyncCompletingActionFromBackgroundQueue() {
        _testAction(TestFeatures.asyncCompletingMainThreadAction,
                    session: .main,
                    callAsync: true,
                    callOnQueue: .global(qos: .background))
    }

    /// Verify that calling an action that must be called on a non-main queue and completes asynchronously does so when called
    /// from the main queue.
    func testBackgroundQueueAsyncCompletingActionFromMainQueue() {
        _testAction(TestFeatures.asyncCompletingBackgroundThreadAction,
                    session: Sessions.backgroundSession,
                    callAsync: false,
                    callOnQueue: nil)
    }
    
    /// Verify that calling an action that must be called on a non-main queue and completes asynchronously does so when called
    /// from the background queue.
    func testBackgroundQueueAsyncCompletingActionFromBackgroundQueue() {
        _testAction(TestFeatures.asyncCompletingBackgroundThreadAction,
                    session: Sessions.backgroundSession,
                    callAsync: true,
                    callOnQueue: SyncBackgroundThreadAction.queue)
    }
    
    func testMainQueueSyncActionFromMainQueueAsynchronously() {
        _testAction(TestFeatures.syncMainThreadAction,
                    session: ActionSession.main,
                    callAsync: true,
                    callOnQueue: .main)
    }


}

// MARK: Helper Types

fileprivate final class AsyncCompletingMainThreadAction: FlintUIAction {
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

fileprivate final class AsyncCompletingBackgroundThreadAction: FlintUIAction {
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

fileprivate final class SyncMainThreadAction: FlintUIAction {
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
