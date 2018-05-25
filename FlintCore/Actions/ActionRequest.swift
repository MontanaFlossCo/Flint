//
//  ActionRequest.swift
//  FlintCore
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An action request encapsulates the information required to perform a single action and perform various action auditing.
///
/// This needs class semantics for identity.
public class ActionRequest<FeatureType: FeatureDefinition, ActionType: Action>: CustomDebugStringConvertible {
    public let date: Date
    public let source: ActionSource
    public let userInitiated: Bool
    public let uniqueID: UInt
    public let sessionName: String
    public let actionBinding: StaticActionBinding<FeatureType, ActionType>
    public let presenter: ActionType.PresenterType
    public let context: ActionContext<ActionType.InputType>

    /// Lazy log creator so it is only created when we need it
    let logContextCreator: ((_ sessionID: String, _ activitySequenceID: String) -> LogEventContext)

    /// The initialiser is internal access only to prevent creation of requests outside of this framework, which could short
    /// circuit some of the safety checks around availability of features
    init(uniqueID: UInt, userInitiated: Bool, source: ActionSource, session: ActionSession, actionBinding: StaticActionBinding<FeatureType, ActionType>,
         input: ActionType.InputType, presenter: ActionType.PresenterType,
         logContextCreator: @escaping ((_ sessionID: String, _ activitySequenceID: String) -> LogEventContext)) {
        date = Date()
        self.uniqueID = uniqueID
        self.source = source
        self.userInitiated = userInitiated
        self.sessionName = session.name
        self.actionBinding = actionBinding
        self.context = ActionContext<ActionType.InputType>(input: input, session: session, source: source)
        self.presenter = presenter
        self.logContextCreator = logContextCreator
    }
    
    /// Use the lazy logger preparation function to set up the loggers
    func prepareLogger(sessionID: String, activitySequenceID: String) {
        let loggingContext = logContextCreator(sessionID, activitySequenceID)
        context.logs.development = Logging.development?.contextualLogger(with: loggingContext)
        context.logs.production = Logging.production?.contextualLogger(with: loggingContext)
    }
    
    public var debugDescription: String {
        if userInitiated {
            return "Request \(uniqueID) for user-initiated \(actionBinding.feature) action \(actionBinding.action)"
        } else {
            return "Request \(uniqueID) for \(actionBinding.feature) action \(actionBinding.action)"
        }
    }
}
