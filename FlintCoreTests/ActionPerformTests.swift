//
//  ActionPerformTests.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore
import XCTest

/// These tests exist primarily to prevent breakage of the public `perform` APIs
class ActionPerformTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Flint.resetForTesting()

        Flint.quickSetup(TestFeatures.self, domains: [], initialDebugLogLevel: .off, initialProductionLogLevel: .off)
    }
    
    func testStaticActionPerformNoInputNoPresenter() {
        var completionCalled = false
        TestFeatures.noInputNoPresenterAction.perform() { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }
        XCTAssert(completionCalled, "Completion was not called")
    }

    func testStaticActionPerformNoInputMockPresenter() {
        var completionCalled = false
        let presenter = MockPresenter()

        TestFeatures.noInputMockPresenterAction.perform(withPresenter: presenter) { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }

        XCTAssert(completionCalled, "Completion was not called")
        XCTAssert(presenter.called, "Presenter was not called")
    }

    func testStaticActionPerformStringInputNoPresenter() {
        var completionCalled = false

        TestFeatures.stringInputNoPresenterAction.perform(withInput: "Wormrot") { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }

        XCTAssert(completionCalled, "Completion was not called")
    }

    func testStaticActionPerformStringInputMockPresenter() {
        var completionCalled = false
        let presenter = MockReturnValuePresenter<String>()

        TestFeatures.stringInputMockPresenterAction.perform(withInput: "Compassion is dead", presenter: presenter) { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }

        XCTAssert(completionCalled, "Completion was not called")
        XCTAssert(presenter.called, "Presenter was not called")
        XCTAssert(presenter.result == "Result: Compassion is dead", "Presenter result was not set")
    }

    func testConditionalActionPerformNoInputNoPresenter() {
        var completionCalled = false
        let request = ConditionalTestFeature.noInputNoPresenterAction.request()
        guard let actionRequest = request else {
            XCTFail("Action not available because feature is conditional and constraints not fulfilled")
            return
        }
        actionRequest.perform() { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }
        XCTAssert(completionCalled, "Completion was not called")
    }

    func testConditionalActionPerformNoInputMockPresenter() {
        var completionCalled = false
        let presenter = MockPresenter()
        let request = ConditionalTestFeature.noInputMockPresenterAction.request()
        guard let actionRequest = request else {
            XCTFail("Action not available because feature is conditional and constraints not fulfilled")
            return
        }
        actionRequest.perform(withPresenter: presenter) { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }

        XCTAssert(completionCalled, "Completion was not called")
        XCTAssert(presenter.called, "Presenter was not called")
    }

    func testConditionalActionPerformStringInputNoPresenter() {
        var completionCalled = false
        let request = ConditionalTestFeature.stringInputNoPresenterAction.request()
        guard let actionRequest = request else {
            XCTFail("Action not available because feature is conditional and constraints not fulfilled")
            return
        }
        actionRequest.perform(withInput: "Wormrot") { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }

        XCTAssert(completionCalled, "Completion was not called")
    }

    func testConditionalActionPerformStringInputMockPresenter() {
        var completionCalled = false
        let presenter = MockReturnValuePresenter<String>()
        let request = ConditionalTestFeature.stringInputMockPresenterAction.request()
        guard let actionRequest = request else {
            XCTFail("Action not available because feature is conditional and constraints not fulfilled")
            return
        }
        actionRequest.perform(withInput: "Compassion is dead", presenter: presenter) { outcome in
            completionCalled = true
            XCTAssert(outcome == .success, "Outcome was not success")
        }

        XCTAssert(completionCalled, "Completion was not called")
        XCTAssert(presenter.called, "Presenter was not called")
        XCTAssert(presenter.result == "Result: Compassion is dead", "Presenter result was not set")
    }}

fileprivate final class NoInputNoPresenterAction: FlintUIAction {
    static func perform(context: ActionContext<NoInput>, presenter: NoPresenter, completion: Completion) -> Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class NoInputMockPresenterAction: FlintUIAction {
    typealias PresenterType = MockPresenter
    
    static func perform(context: ActionContext<NoInput>, presenter: MockPresenter, completion: Completion) -> Completion.Status {
        presenter.actionWorkWasDone()
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class StringInputNoPresenterAction: FlintUIAction {
    typealias InputType = String
    
    static func perform(context: ActionContext<String>, presenter: NoPresenter, completion: Completion) -> Completion.Status {
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class StringInputMockPresenterAction: FlintUIAction {
    typealias InputType = String
    typealias PresenterType = MockReturnValuePresenter<String>

    static func perform(context: ActionContext<String>, presenter: MockReturnValuePresenter<String>, completion: Completion) -> Completion.Status {
        presenter.actionWorkWasDone("Result: \(context.input)")
        return completion.completedSync(.successWithFeatureTermination)
    }
}

fileprivate final class ConditionalTestFeature: ConditionalFeature {
    static func constraints(requirements: FeatureConstraintsBuilder) {
    }
    
    static var description: String = "Conditional test feature, always available"

    static let noInputNoPresenterAction = action(NoInputNoPresenterAction.self)
    static let noInputMockPresenterAction = action(NoInputMockPresenterAction.self)
    static let stringInputNoPresenterAction = action(StringInputNoPresenterAction.self)
    static let stringInputMockPresenterAction = action(StringInputMockPresenterAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(noInputNoPresenterAction)
        actions.declare(noInputMockPresenterAction)
        actions.declare(stringInputNoPresenterAction)
        actions.declare(stringInputMockPresenterAction)
    }
}

fileprivate final class TestFeatures: Feature, FeatureGroup {
    static var subfeatures: [FeatureDefinition.Type] = [ConditionalTestFeature.self]
    
    static var description: String = "Test Features"
    
    static let noInputNoPresenterAction = action(NoInputNoPresenterAction.self)
    static let noInputMockPresenterAction = action(NoInputMockPresenterAction.self)
    static let stringInputNoPresenterAction = action(StringInputNoPresenterAction.self)
    static let stringInputMockPresenterAction = action(StringInputMockPresenterAction.self)
    
    static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(noInputNoPresenterAction)
        actions.declare(noInputMockPresenterAction)
        actions.declare(stringInputNoPresenterAction)
        actions.declare(stringInputMockPresenterAction)
    }
}
