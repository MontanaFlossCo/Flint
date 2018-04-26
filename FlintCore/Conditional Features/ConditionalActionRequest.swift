//
//  ConditionalActionRequest.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A type used to prevent direct execution of actions on `ConditionalFeature`(s), such that
/// `ActionSession` only has functions to perform actions using `ConditionalActionRequest` and not
/// a `perform()` using a `ConditionalActionBinding`.
///
/// The protocol extensions on `ConditionalFeature` only supports
/// `request` and not `perform`, forcing the caller to test if the feature is available first and at least
/// explicitly ignore the "feature not available" path, but hopefully provide a code path for that.
public struct ConditionalActionRequest<FeatureType, ActionType> where FeatureType: ConditionalFeature, ActionType: Action {
    public let actionBinding: ConditionalActionBinding<FeatureType, ActionType>
    
    /// Force this to be internal, so that callers cannot just create a request to bypass conditional testing
    internal init(actionBinding: ConditionalActionBinding<FeatureType, ActionType>) {
        self.actionBinding = actionBinding
    }

    public func perform(using presenter: ActionType.PresenterType,
                       with input: ActionType.InputType,
                       completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: presenter, with: input, completion: completion)
    }
    
    public func perform(using presenter: ActionType.PresenterType,
                       with input: ActionType.InputType,
                       userInitiated: Bool,
                       source: ActionSource = .application,
                       completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: presenter, with: input, userInitiated: userInitiated, source: source, completion: completion)
    }
}

extension ConditionalActionRequest where ActionType.PresenterType == NoPresenter {
    public func perform(with input: ActionType.InputType,
                        completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: NoPresenter(), with: input, completion: completion)
    }

    public func perform(with input: ActionType.InputType,
                        userInitiated: Bool,
                        source: ActionSource,
                        completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: NoPresenter(), with: input, userInitiated: userInitiated, source: source, completion: completion)
    }
}

extension ConditionalActionRequest where ActionType.InputType == NoInput {
    public func perform(using presenter: ActionType.PresenterType,
                        completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: presenter, with: NoInput.none, completion: completion)
    }

    public func perform(using presenter: ActionType.PresenterType,
                        userInitiated: Bool,
                        source: ActionSource,
                        completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: presenter, with: NoInput.none, userInitiated: userInitiated, source: source, completion: completion)
    }
}

extension ConditionalActionRequest where ActionType.InputType == NoInput, ActionType.PresenterType == NoPresenter {
    public func perform(completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: NoPresenter(), with: NoInput.none, completion: completion)
    }

    public func perform(userInitiated: Bool,
                        source: ActionSource,
                        completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: NoPresenter(), with: NoInput.none, userInitiated: userInitiated, source: source, completion: completion)
    }
}
