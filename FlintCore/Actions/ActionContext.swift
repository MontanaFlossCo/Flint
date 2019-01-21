//
//  ActionContext.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 05/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The context in which an action executes. Contains the initial state and contextual logger.
///
/// The context can be passed forward, or a new instance derived with new state, so that e.g. a subsystem can be
/// passed the logger and state information as a single opaque value, without passing forward the entire action request
public class ActionContext<InputType> where InputType: FlintLoggable {
    /// The input to the action
    public let input: InputType

    /// The contextual logs for the action
    private let logsMutex = DispatchSemaphore(value: 1)
    private var _logs: ContextualLoggers?
    public var logs: ContextualLoggers {
        defer {
            logsMutex.signal()
        }
        logsMutex.wait()
        if let _logs = _logs {
            return _logs
        }
        
        guard let logSetup = self.logSetup else {
            flintBug("Log setup callback was not set on ActionContext before logs were accessed")
        }
        let result = logSetup()
        _logs = result
        return result
    }
    
    /// The source of the action, used to tell if it came from the application itself or e.g. Siri.
    public let source: ActionSource
    
    private let session: ActionSession
    
    /// Set internally once during two-phase creation of the context
    var logSetup: (() -> ContextualLoggers)?
    
    init(input: InputType, session: ActionSession, source: ActionSource) {
        self.input = input
        self.session = session
        self.source = source
    }

    /// Perform the action in the same session as this current action request, passing on the contextual loggers
    /// Use this to perform other actions within action implementations.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                           input: ActionType.InputType,
                           presenter: ActionType.PresenterType,
                           userInitiated: Bool,
                           completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(actionBinding, input: input, presenter: presenter, userInitiated: userInitiated, source: source, completion: completion)
    }
    
    /// Perform the action in the same session as this current action request, passing on the contextual loggers
    /// Use this to perform other actions within action implementations.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: VerifiedActionBinding<FeatureType, ActionType>,
                           input: ActionType.InputType,
                           presenter: ActionType.PresenterType,
                           userInitiated: Bool,
                           completion: ((ActionOutcome) -> ())? = nil) {
        session.perform(conditionalRequest, input: input, presenter: presenter, userInitiated: userInitiated, source: source, completion: completion)
    }

    public var debugDescriptionOfInput: String? {
        if input is NoInput {
            return nil
        } else {
            return String(reflecting: input)
        }
    }
}
