//
//  StaticActionBinding.swift
//  FlintCore
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Represents the binding of an action to a specific unconditional `Feature`.
///
/// These are use as the main entry point for performing actions, having been bound using the `action` function
/// of `Feature` (provided by a protocol extension).
///
/// ```
/// class DocumentManagementFeature: Feature {
///     static let description = "Create documents"
///
///     // This is where the binding is created
///     static let createNew = action(DocumentCreateAction.self)
///
///     static func prepare(actions: FeatureActionsBuilder) {
///         actions.declare(createNew)
///     }
/// }
///
/// ... later you can perform the action directly ...
///
/// DocumentManagementFeature.createNew.perform( ... )
/// ```
public struct StaticActionBinding<FeatureType, ActionType>: CustomDebugStringConvertible where FeatureType: FeatureDefinition, ActionType: Action {

    /// The feature to which the action is bounc
    public let feature: FeatureType.Type
    
    /// The action bound to the feature
    public let action: ActionType.Type
    
    private var _logTopicPath: TopicPath?
    /// The `TopicPath` to use when outputting logging for this action
    public var logTopicPath: TopicPath { return _logTopicPath! }

    /// This initialiser is `internal` and must remain so to prevent misuse where static bindings could be created
    /// and directly performed even if they are only meant to be conditionally available.
    init(feature: FeatureType.Type, action: ActionType.Type) {
        self.feature = feature
        self.action = action
        _logTopicPath = TopicPath(actionBinding: self)
    }
    
    public var debugDescription: String {
        return "\(feature)'s action \(action)"
    }

    /// A convenience function to perform the action in the main `ActionSession`.
    ///
    /// This function performs the action assuming the user initiated the action, and the application was the source
    /// of the request.
    ///
    /// The completion handler is called on main queue because the action is performed in the main `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform(using presenter: ActionType.PresenterType,
                           with input: ActionType.InputType,
                           completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: presenter, with: input, completion: completion)
    }

    /// A convenience function to perform the action in the main `ActionSession`
    ///
    /// The completion handler is called on main queue because the action is performed in the main `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param userInitiated: Set to `true` if the user explicitly chose to perform this action, `false` if not
    /// - param source: Indicates where the request came from
    /// - param completion: The completion handler to call.
    public func perform(using presenter: ActionType.PresenterType,
                           with input: ActionType.InputType,
                           userInitiated: Bool,
                           source: ActionSource,
                           completion: ((ActionOutcome) -> ())? = nil) {
        ActionSession.main.perform(self, using: presenter, with: input, userInitiated: userInitiated, source: source, completion: completion)
    }
}
