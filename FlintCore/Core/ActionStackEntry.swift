//
//  ActionStackEntry.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An encapsulation of a single Action Stack entry.
///
/// This is intentionally lightweight, so it does not retain objects from your app, using simplified
/// representations instead.
///
/// This is explicitly immutable as entries cannot be changed after the fact.
public struct ActionStackEntry: CustomDebugStringConvertible {
    public enum Details {
        case action(name: String, source: ActionSource, input: String?)
        case substack(stack: ActionStack)
    }
    
    /// The time the action stack was created
    public let startDate = Date()
    
    /// The time since the action stack was created
    public var timeIntervalSinceStart: TimeInterval { return -startDate.timeIntervalSinceNow }
    
    /// Indicates whether or not the user explicitly invoked this action
    public let userInitiated: Bool
    
    /// The feature to which the action belonged
    public let feature: FeatureDefinition.Type
    
    /// The details of the entry, whether it was an action (and the information for that), or a new nested actions stack
    public let details: Details
    
    /// The name of the session the action was performed in
    public let sessionName: String
    
    /// Initialise the entry capturing only simple types and without retaining anything from the request.
    init<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, sessionName: String) {
        userInitiated = request.userInitiated
        feature = request.actionBinding.feature
        details = .action(name: request.actionBinding.action.name,
                          source: request.source,
                          input: String(reflecting: request.context.input))
        self.sessionName = sessionName
        // Do this so that we don't retain the request.
        debugDescription = request.debugDescription
    }
    
    init(_ substack: ActionStack, userInitiated: Bool) {
        self.userInitiated = userInitiated
        feature = substack.feature
        details = .substack(stack: substack)
        sessionName = substack.sessionName
        debugDescription = substack.debugDescription
    }
    
    public private(set) var debugDescription: String
}
