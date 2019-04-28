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

    public var inputLoggingDescription: String {
        return propertyAccessQueue.sync {
            // If it is nil, it is because the input is immutable and we can safely create the description lazily.
            // If it is not nil, it is because the input is mutable and we already captured it earlier
            if _inputLoggingDescription == nil {
                // Capture immutable description once, for performance
                guard ActionType.InputType.isImmutableForLogging else {
                    flintBug("No logging description captured, but input is not returning false for isImmutableForLogging")
                }
                _inputLoggingDescription = context.input.loggingDescription
            }
            return _inputLoggingDescription!
        }
    }

    public var inputLoggingInfo: [String:String]? {
        return propertyAccessQueue.sync {
            // If it is nil, it is because the input is immutable and we can safely create the description lazily.
            // If it is not nil, it is because the input is mutable and we already captured it earlier
            if !_inputLoggingInfoChecked && _inputLoggingInfo == nil {
                // Capture immutable description once, for performance
                guard ActionType.InputType.isImmutableForLogging else {
                    flintBug("No logging description captured, but input is not async loggable")
                }
                _inputLoggingInfo = context.input.loggingInfo
                _inputLoggingInfoChecked = true
            }
            return _inputLoggingInfo
        }
    }

    private var _inputLoggingDescription: String?
    private var _inputLoggingInfo: [String:String]?
    
    /// Set to true once `loggingInfo` has been called on the input. As this can return nil we need to remember
    /// that we did this to avoid calling it repeatedly
    private var _inputLoggingInfoChecked: Bool = false

    private lazy var propertyAccessQueue: DispatchQueue = { DispatchQueue(label: "tools.flint.ActionRequest-state") }()

    /// Lazy log creator so it is only created when we need it
    let logContextCreator: (_ request: ActionRequest<FeatureType, ActionType>, _ sessionID: String, _ activitySequenceID: String) -> LogEventContext
    private var loggingSessionDetailsCreator: (() -> (sessionID: String, activitySequenceID: String))?
    
    /// The initialiser is internal access only to prevent creation of requests outside of this framework, which could short
    /// circuit some of the safety checks around availability of features
    init(uniqueID: UInt, userInitiated: Bool, source: ActionSource, session: ActionSession, actionBinding: StaticActionBinding<FeatureType, ActionType>,
         input: ActionType.InputType, presenter: ActionType.PresenterType,
         logContextCreator: @escaping (_ request: ActionRequest<FeatureType, ActionType>, _ sessionID: String, _ activitySequenceID: String) -> LogEventContext) {
        date = Date()
        self.uniqueID = uniqueID
        self.source = source
        self.userInitiated = userInitiated
        self.sessionName = session.name
        self.actionBinding = actionBinding
        self.presenter = presenter
        self.logContextCreator = logContextCreator
        self.context = ActionContext<ActionType.InputType>(input: input, session: session, source: source)
        self.context.logSetup = prepareLogs
        if !ActionType.InputType.isImmutableForLogging {
            _inputLoggingDescription = context.input.loggingDescription
            _inputLoggingInfo = context.input.loggingInfo
            _inputLoggingInfoChecked = true
        }
    }
    
    /// Use the lazy logger preparation function to set up the loggers
    func setLoggingSessionDetailsCreator(_ creator: @escaping () -> (sessionID: String, activitySequenceID: String)) {
        loggingSessionDetailsCreator = creator
    }
    
    func prepareLogs() -> ContextualLoggers {
        guard let loggingSessionDetailsCreator = loggingSessionDetailsCreator else {
            flintBug("loggingSessionDetailsCreator has to be set before loggers can be built")
        }
        let (sessionID, activitySequenceID) = loggingSessionDetailsCreator()
        let loggingContext = logContextCreator(self, sessionID, activitySequenceID)
        let logs = ContextualLoggers(development: Logging.development?.contextualLogger(with: loggingContext),
                        production: Logging.production?.contextualLogger(with: loggingContext))
        return logs
    }
    
    public var debugDescription: String {
        if userInitiated {
            return "Request \(uniqueID) for user-initiated \(FeatureType.self) action \(ActionType.self)"
        } else {
            return "Request \(uniqueID) for \(FeatureType.self) action \(ActionType.self)"
        }
    }
}
