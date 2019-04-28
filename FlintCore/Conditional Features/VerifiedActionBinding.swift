//
//  VerifiedActionBinding.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A type used to prevent direct execution of actions on `ConditionalFeature`(s), such that
/// `ActionSession` only has functions to perform actions using `VerifiedActionBinding` and not
/// a `perform()` using a `ConditionalActionBinding`.
///
/// This makes it impossible to directly perform an action of a conditional feature without first requesting access to it,
/// as these request instances are only created by the framework and must be used to perform such actions.
///
/// The protocol extensions on `ConditionalFeature` only supports
/// `request` and not `perform`, forcing the caller to test if the feature is available first and at least
/// explicitly ignore the "feature not available" path, but hopefully provide a code path for that.
public struct VerifiedActionBinding<FeatureType, ActionType> where FeatureType: ConditionalFeature, ActionType: Action {
    public let actionBinding: ConditionalActionBinding<FeatureType, ActionType>
    
    private var session: ActionSession {
        guard let result = ActionType.defaultSession else {
            flintUsageError("You cannot call `perform` on action bindings directly unless the Action defines a value for `defaultSession`. Perhaps you mean your action to conform to UIAction, which uses the main session?")
        }
        return result
    }
    
    /// Force this to be internal, so that callers cannot just create a request to bypass conditional testing
    internal init(actionBinding: ConditionalActionBinding<FeatureType, ActionType>) {
        self.actionBinding = actionBinding
    }

    public func perform(input: ActionType.InputType,
                        presenter: ActionType.PresenterType,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: input, presenter: presenter, completion: completion)
    }
    
    public func perform(input: ActionType.InputType,
                        presenter: ActionType.PresenterType,
                        userInitiated: Bool,
                        source: ActionSource = .application,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: input, presenter: presenter, userInitiated: userInitiated, source: source, completion: completion)
    }

    public func perform(input: ActionType.InputType,
                        presenter: ActionType.PresenterType,
                        userInitiated: Bool,
                        source: ActionSource = .application,
                        completion: Action.Completion) -> Action.Completion.Status {
        return session.perform(self, input: input, presenter: presenter, userInitiated: userInitiated, source: source, completionRequirement: completion)
    }
}

/// Overloads for actions with no presenter
extension VerifiedActionBinding where ActionType.PresenterType == NoPresenter {
    public func perform(input: ActionType.InputType,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: input, presenter: NoPresenter(), completion: completion)
    }

    public func perform(input: ActionType.InputType,
                        userInitiated: Bool,
                        source: ActionSource,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: input, presenter: NoPresenter(), userInitiated: userInitiated, source: source, completion: completion)
    }
}

/// Overloads for actions with no input
extension VerifiedActionBinding where ActionType.InputType == NoInput {
    public func perform(presenter: ActionType.PresenterType,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: .noInput, presenter: presenter, completion: completion)
    }

    public func perform(presenter: ActionType.PresenterType,
                        userInitiated: Bool,
                        source: ActionSource,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: .noInput, presenter: presenter, userInitiated: userInitiated, source: source, completion: completion)
    }
}

/// Overloads for actions with neither input nor presenter
extension VerifiedActionBinding where ActionType.InputType == NoInput, ActionType.PresenterType == NoPresenter {
    public func perform(completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: .noInput, presenter: NoPresenter(), completion: completion)
    }

    public func perform(userInitiated: Bool,
                        source: ActionSource,
                        completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(self, input: .noInput, presenter: NoPresenter(), userInitiated: userInitiated, source: source, completion: completion)
    }
}
