//
//  FeatureSession.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/10/2017.
//  Copyright © 2017 Montana Floss Co. All rights reserved.
//

import Foundation

/// An ActionSession is used to group a bunch of Action invocations, ensure they are invoked on the expected queue,
/// and track the Action Stacks that result from performing actions.
///
/// The session used for an action invocation is recorded in Flint timelines and logs to aid in debugging.
///
/// The default `ActionSession.main` session provided is what your UI will use most of the time. However if
/// your application supports multiple concurrent windows or documents you may wish to create more so that
/// you can see timeline and log events broken down per window or document, e.g. with the session name equal to the
/// document name or a symbolic equivalent of it for privacy. This way you can see what the user is doing in a multi-context environment.
///
/// Furthermore, if your application performs background tasks you should consider creation a session for these.
///
/// The lifetime of an ActionStack can be tracked in logging and analytics and tied to a specific activity session,
/// and is demarcated by the first use of an action from a feature, and the action that indicates termination of the current "feature".
///
/// - note: A session can only be used from a single thread or queue, the queue set when creating the session.
/// The dispatcher will ensure that the actions are called on the queues they expect, without excessive queue hops.
/// !!! TODO: Extract protocol for easier testing
public class ActionSession: CustomDebugStringConvertible {
    
    /// The default `ActionSession` used for user interactions with the app. This is similar to,
    /// but not identical to the idea of `DispatchQueue.main`. The action session is a higher level
    /// idea about what the user's current activity is in the app. The features in use at any one
    /// time are inferred by the actions being performed in the action session.
    ///
    /// As such it is not possible to be using the same `Feature` more than once concurrently in the same action
    /// session. In the example of a multi-window or multi-tabbed application, you would create a new explicit
    /// action session per window or tab, and perform actions in those sessions to correctly track the active `Feature`(s).
    public static let main: ActionSession = ActionSession(named: "main",
                                                          userInitiatedActions: true,
                                                          dispatcher: Flint.dispatcher,
                                                          actionStackTracker: ActionStackTracker.instance)

    /// The name of the session, for debug, analytics and logging purposes
    public let name: String
    
    /// Whether or not this session is for user-initiated actions rather than internal actions.
    public let userInitiatedActions: Bool
    
    /// The dispatcher to use
    public let dispatcher: ActionDispatcher

    /// The ActionStackTracker
    public let actionStackTracker: ActionStackTracker
    
    /// The currently active action request. If this is non-nil, an action is currently being performed
    /// and awaiting completion
    public var currentActionStackEntry: ActionStackEntry?

    /// The queue on which `perform` should always be called – failure to do so will result in an error.
    public let callerQueue: DispatchQueue
    lazy var smartCallerQueue: SmartDispatchQueue = {
        return SmartDispatchQueue(queue: callerQueue, owner: self)
    }()

    /// An internal counter for the request IDs
    private var currentRequestID: UInt = 0
    
    /// Initialise a session
    /// - param name: The name of the session, e.g. "main" or "bgtasks" or "document-3"
    /// - param userInitiatedActions: Set to `true` if by default the actions for this session are always initiated by the user.
    /// This avoids you having to specify this when calling `perform`
    /// - param dispatch: The dispatcher to use
    /// - param actionStackTracker: The action stack tracker that will be used
    /// - param callerQueue: The queue that all future calls to `perform` are expected to be on.
    public init(named name: String, userInitiatedActions: Bool, dispatcher: ActionDispatcher, actionStackTracker: ActionStackTracker, callerQueue: DispatchQueue = .main) {
        self.userInitiatedActions = userInitiatedActions
        self.dispatcher = dispatcher
        self.actionStackTracker = actionStackTracker
        self.name = name
        self.callerQueue = callerQueue
    }
    
    /// Call to set up the standard action start/stop logging
    public static func quickSetupMainSession() {
        // Logs begin/complete of all actions
        ActionSession.main.dispatcher.add(observer: ActionLoggingDispatchObserver.instance)
    }
    
    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 using presenter: ActionType.PresenterType,
                                                 with input: ActionType.InputType,
                                                 completion: ((ActionOutcome) -> ())? = nil) {
        perform(conditionalRequest, using: presenter, with: input, userInitiated: userInitiatedActions, source: .application, completion: completion)
    }
    
    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 with input: ActionType.InputType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.PresenterType == NoPresenter {
        perform(conditionalRequest, using: NoPresenter(), with: input, userInitiated: userInitiatedActions, source: .application, completion: completion)
    }

    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 using presenter: ActionType.PresenterType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput {
        perform(conditionalRequest, using: presenter, with: .none, userInitiated: userInitiatedActions, source: .application, completion: completion)
    }

    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput, ActionType.PresenterType == NoPresenter {
        perform(conditionalRequest, using: NoPresenter(), with: .none, userInitiated: userInitiatedActions, source: .application, completion: completion)
    }

    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param userInitiated: Set to `true` if the user explicitly chose to perform this action, `false` if not
    /// - param source: Indicates where the request came from
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                       using presenter: ActionType.PresenterType,
                       with input: ActionType.InputType,
                       userInitiated: Bool,
                       source: ActionSource,
                       completion: ((ActionOutcome) -> ())? = nil) {
        let staticBinding = StaticActionBinding(feature: conditionalRequest.actionBinding.feature, action: conditionalRequest.actionBinding.action)
        let logContextCreator = { (sessionID, activitySequenceID) in
            return LogEventContext(session: sessionID,
                                   activity: activitySequenceID,
                                   topicPath: TopicPath(actionBinding: staticBinding),
                                   arguments: input.description,
                                   presenter: String(describing: presenter))
        }
        let actionRequest = ActionRequest(uniqueID: nextRequestID(),
                                          userInitiated: userInitiated,
                                          source: source,
                                          session: self,
                                          actionBinding: staticBinding,
                                          input: input,
                                          presenter: presenter,
                                          logContextCreator: logContextCreator)
        perform(actionRequest, completion: completion)
    }
    

    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 using presenter: ActionType.PresenterType,
                                                 with input: ActionType.InputType,
                                                 completion: ((ActionOutcome) -> ())? = nil) {
        perform(actionBinding, using: presenter, with: input, userInitiated: userInitiatedActions,
                source: .application, completion: completion)
    }
    
    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available, when they have no presenter (`NoPresenter`) requirement.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 with input: ActionType.InputType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.PresenterType == NoPresenter {
        perform(actionBinding, using: NoPresenter(), with: input, userInitiated: userInitiatedActions,
                source: .application, completion: completion)
    }

    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available, when they have no input (`NoInput`) requirement.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 using presenter: ActionType.PresenterType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput {
        perform(actionBinding, using: presenter, with: .none, userInitiated: userInitiatedActions,
                source: .application, completion: completion)
    }

    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available, when they have no input (`NoInput`) requirement and
    /// no presenter (`NoPresenter`) requirement.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput, ActionType.PresenterType == NoPresenter {
        perform(actionBinding, using: NoPresenter(), with: .none, userInitiated: userInitiatedActions,
                source: .application, completion: completion)
    }

    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param userInitiated: Set to `true` if the user explicitly chose to perform this action, `false` if not
    /// - param source: Indicates where the request came from
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                       using presenter: ActionType.PresenterType,
                       with input: ActionType.InputType,
                       userInitiated: Bool,
                       source: ActionSource,
                       completion: ((ActionOutcome) -> ())? = nil) {
        let logContextCreator = { (sessionID, activitySequenceID) in
            return LogEventContext(session: sessionID,
                                   activity: activitySequenceID,
                                   topicPath: actionBinding.logTopicPath,
                                   arguments: input.description,
                                   presenter: String(describing: presenter))
        }
        let request: ActionRequest<FeatureType, ActionType> = ActionRequest(uniqueID: nextRequestID(),
                                                      userInitiated: userInitiated,
                                                      source: source,
                                                      session: self,
                                                      actionBinding: actionBinding,
                                                      input: input,
                                                      presenter: presenter,
                                                      logContextCreator: logContextCreator)
        perform(request, completion: completion)
    }
    
    // MARK: Debug helpers
    
    public var debugDescription: String {
        return "Action session \(name)"
    }

    // MARK: Internals

    private func nextRequestID() -> UInt {
        currentRequestID = currentRequestID &+ 1
        return currentRequestID
    }

    /// Execute the action of the request, appending it to the action sequence for the relevant feature
    /// - note: This is the heart of the Features implementation.
    private func perform<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, completion: ((ActionOutcome) -> ())?) {
        if !smartCallerQueue.isCurrentQueue {
            let message = "Called ActionSession \"\(self.name)\" from a queue that is not \(self.callerQueue). Failing fast because this implies your completion will execute on a different queue to the one you expect"
            FlintInternal.logger?.error(message)
            fatalError(message)
        }

        Flint.requiresSetup()
        Flint.requiresPrepared(feature: request.actionBinding.feature)
        
        // Work out if we have a sequence for the request's feature, create a new one if not
        let actionStack = actionStackTracker.findOrCreateActionStack(for: request.actionBinding.feature,
                                                                                 in: self,
                                                                                 userInitiated: request.userInitiated)

        let firstEntry = actionStack.entries.first?.debugDescription ?? request.actionBinding.action.name
        let aDescription = "\(actionStack.feature.name) - step #\(request.uniqueID): \(firstEntry)"
        let activityID = "Stack #\(actionStack.id) \(aDescription)"
        request.prepareLogger(sessionID: name, activitySequenceID: activityID)
        
        // Create the entry and add it to the sequence
        let entry = ActionStackEntry(request, sessionName: name)
        actionStack.add(entry: entry)
        
        // Each session can be used by only one thread, and as such we can remember the "most recent" action request
        currentActionStackEntry = entry

        // By the magic of closures we get to capture the Action Stack that the action request is part of here
        // and can terminate the correct one
        let _ = dispatcher.perform(request: request, callerQueue: smartCallerQueue, completion: { outcome in
            /// !!! TODO: What is the contract re: actions calling completion on a given queue?

            // Report outcome to the caller, minus our internals about action stacks
            completion?(outcome.simplifiedOutcome)

            // Terminate the current stack if required
            switch outcome {
                case .success(closeActionStack: true),
                     .failure(error: _, closeActionStack: true):
                   self.actionStackTracker.terminate(actionStack, actionRequest: request)
                default:
                    break
            }
        })
    }
}
