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
/// ## Threading
///
/// A session can only be used from a single thread or queue, the queue set when creating the session. This is known as the
/// `callerQueue`.
///
/// Actions can select which queue they will be called to `perform` on, via their `queue` property. This is *always*
/// the queue they will execute on, and may be entirely different from the session's queue.
///
/// This mechanism guarantees that code calling into an `ActionSession` does not need to care about the queue an Action expects,
/// and Actions do not need to care about the queue they are called on, thus eliminating excessive thread hops (AKA "mmm, just DispatchQueue.async it").
/// This reduces "slushiness" and lag in UIs, and makes it easier to reason about the code.
///
/// The dispatcher will ensure that the Actions are called synchronously on their desired queue, even if that is the same as the current queue.
/// It will also make sure that they call their completion handler on the session's `callerQueue`, without excessive queue hops
/// so that if the caller is already on the correct thread, there is no async dispatch required.
///
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
                                                          userInitiatedActions: true)

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
    /// The completion callbacks will always be called on this queue, either synchronously or asynchronously depending
    /// on how the Action calls completion.
    public let callerQueue: DispatchQueue
    lazy var smartCallerQueue: SmartDispatchQueue = {
        return SmartDispatchQueue(queue: callerQueue)
    }()

    /// An internal counter for the request IDs
    private var currentRequestID: UInt = 0
    
    /// Initialise a session
    /// - param name: The name of the session, e.g. "main" or "bgtasks" or "document-3"
    /// - param userInitiatedActions: Set to `true` if by default the actions for this session are always initiated by the user.
    /// - param callerQueue: The queue that all future calls to `perform` are expected to be on.
    /// This avoids you having to specify this when calling `perform`
    /// - param dispatch: The dispatcher to use, defaults to the global Flint dispatcher
    /// - param actionStackTracker: The action stack tracker that will be used, defaults to the shared tracker instance
    public init(named name: String,
                userInitiatedActions: Bool,
                callerQueue: DispatchQueue = .main,
                dispatcher: ActionDispatcher = Flint.dispatcher,
                actionStackTracker: ActionStackTracker = .instance) {
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
                                                 input: ActionType.InputType,
                                                 presenter: ActionType.PresenterType,
                                                 completion: ((ActionOutcome) -> ())? = nil) {
        perform(conditionalRequest, input: input, presenter: presenter, userInitiated: userInitiatedActions, source: .application, completion: completion)
    }
    
    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param input: The value to pass as the input of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 input: ActionType.InputType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.PresenterType == NoPresenter {
        perform(conditionalRequest, input: input, presenter: NoPresenter(), userInitiated: userInitiatedActions, source: .application, completion: completion)
    }

    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 presenter: ActionType.PresenterType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput {
        perform(conditionalRequest, input: .none, presenter: presenter, userInitiated: userInitiatedActions, source: .application, completion: completion)
    }

    /// Perform the action associated with a conditional request obtained from `ConditionalFeature.request`.
    ///
    /// This is how you execute actions that are not always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput, ActionType.PresenterType == NoPresenter {
        perform(conditionalRequest, input: .none, presenter: NoPresenter(), userInitiated: userInitiatedActions, source: .application, completion: completion)
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
                                                 input: ActionType.InputType,
                                                 presenter: ActionType.PresenterType,
                                                 userInitiated: Bool,
                                                 source: ActionSource,
                                                 completion: ((ActionOutcome) -> ())? = nil) {
        let staticBinding = StaticActionBinding(feature: conditionalRequest.actionBinding.feature, action: conditionalRequest.actionBinding.action)
        let logContextCreator = { (sessionID, activitySequenceID) in
            return LogEventContext(session: sessionID,
                                   activity: activitySequenceID,
                                   topicPath: TopicPath(actionBinding: staticBinding),
                                   arguments: input.loggingDescription,
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
    /// - param completionRequirement: The completion object to use.
    /// - return: The completion status, indicating whether it was synchronously completed or not, and the result if so.
    public func perform<FeatureType, ActionType>(_ conditionalRequest: ConditionalActionRequest<FeatureType, ActionType>,
                                                 input: ActionType.InputType,
                                                 presenter: ActionType.PresenterType,
                                                 userInitiated: Bool,
                                                 source: ActionSource,
                                                 completionRequirement: Action.Completion) -> Action.Completion.Status {
        let staticBinding = StaticActionBinding(feature: conditionalRequest.actionBinding.feature, action: conditionalRequest.actionBinding.action)
        let logContextCreator = { (sessionID, activitySequenceID) in
            return LogEventContext(session: sessionID,
                                   activity: activitySequenceID,
                                   topicPath: TopicPath(actionBinding: staticBinding),
                                   arguments: input.loggingDescription,
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
        return perform(actionRequest, completionRequirement: completionRequirement)
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
                                                 input: ActionType.InputType,
                                                 presenter: ActionType.PresenterType,
                                                 completion: ((ActionOutcome) -> ())? = nil) {
        perform(actionBinding, input: input, presenter: presenter, userInitiated: userInitiatedActions,
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
                                                 input: ActionType.InputType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.PresenterType == NoPresenter {
        perform(actionBinding, input: input, presenter: NoPresenter(), userInitiated: userInitiatedActions,
                source: .application, completion: completion)
    }

    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available, when they have no input (`NoInput`) requirement.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The presenter to pass to the action
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 presenter: ActionType.PresenterType,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput {
        perform(actionBinding, input: .none, presenter: presenter, userInitiated: userInitiatedActions,
                source: .application, completion: completion)
    }

    /// Perform an action associated with an unconditional `Feature`.
    ///
    /// This is how you execute actions that are always available, when they have no input (`NoInput`) requirement and
    /// no presenter (`NoPresenter`) requirement.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param completion: The completion handler to call.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 completion: ((ActionOutcome) -> ())? = nil)
                                                 where ActionType.InputType == NoInput, ActionType.PresenterType == NoPresenter {
        perform(actionBinding, input: .none, presenter: NoPresenter(), userInitiated: userInitiatedActions,
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
                                                 input: ActionType.InputType,
                                                 presenter: ActionType.PresenterType,
                                                 userInitiated: Bool,
                                                 source: ActionSource,
                                                 completion: ((ActionOutcome) -> ())? = nil) {
        let logContextCreator = { (sessionID, activitySequenceID) in
            return LogEventContext(session: sessionID,
                                   activity: activitySequenceID,
                                   topicPath: actionBinding.logTopicPath,
                                   arguments: input.loggingDescription,
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
    
    /// Perform an action associated with an unconditional `Feature`, returning completion status.
    ///
    /// This is how you execute actions that are always available.
    ///
    /// The completion handler is called on `callerQueue` of this `ActionSession`
    ///
    /// - param presenter: The object presenting the outcome of the action
    /// - param input: The value to pass as the input of the action
    /// - param userInitiated: Set to `true` if the user explicitly chose to perform this action, `false` if not
    /// - param source: Indicates where the request came from
    /// - param completionRequirement: The completion requirement to use.
    /// - return: The completion status, indicating whether or not completion is being called synchronously, and including completion results.
    public func perform<FeatureType, ActionType>(_ actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                 input: ActionType.InputType,
                                                 presenter: ActionType.PresenterType,
                                                 userInitiated: Bool,
                                                 source: ActionSource,
                                                 completionRequirement: Action.Completion) -> Action.Completion.Status {
        let logContextCreator = { (sessionID, activitySequenceID) in
            return LogEventContext(session: sessionID,
                                   activity: activitySequenceID,
                                   topicPath: actionBinding.logTopicPath,
                                   arguments: input.loggingDescription,
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
        return perform(request, completionRequirement: completionRequirement)
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
        let completionRequirement = Action.Completion() { outcome, completedAsync in
            completion?(outcome.simplifiedOutcome)
        }
        
        // For these kinds of invocations we care not about the sync/async status
        let _ = perform(request, completionRequirement: completionRequirement)
    }
    
    func perform<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, completionRequirement: Action.Completion) -> Action.Completion.Status {
        if !smartCallerQueue.isCurrentQueue {
            let message = "Called ActionSession \"\(self.name)\" from a queue that is not \(self.callerQueue). Failing fast because this implies your completion will execute on a different queue to the one you expect"
            FlintInternal.logger?.error(message)
            flintUsageError(message)
        }

        // Sanity checks and footgun avoidance
        Flint.requiresSetup()
        Flint.requiresPrepared(feature: request.actionBinding.feature)
        guard Flint.isDeclared(request.actionBinding.action, on: request.actionBinding.feature) else {
            flintUsageError("Action \(request.actionBinding.action) has not been declared on \(request.actionBinding.feature). Call 'declare' or 'publish' with it in your feature's prepare function")
        }
        
        // Work out if we have a sequence for the request's feature, create a new one if not
        let actionStack = actionStackTracker.findOrCreateActionStack(for: request.actionBinding.feature,
                                                                     in: self,
                                                                     userInitiated: request.userInitiated)

        // Set up the lazy creator for the log details, so no work is done unless the details are needed
        request.setLoggingSessionDetailsCreator { [weak self] in
            guard let strongSelf = self else {
                return (sessionID: "_session gone away_", activitySequenceID: "_session gone away_")
            }
            let firstEntry = actionStack.first?.debugDescription ?? request.actionBinding.action.name
            let aDescription = "\(actionStack.feature.name) - step #\(request.uniqueID): \(firstEntry)"
            let activityID = "Stack #\(actionStack.id) \(aDescription)"
            return (sessionID: strongSelf.name, activitySequenceID: activityID)
        }
        
        // Create the entry and add it to the sequence
        let entry = ActionStackEntry(request, sessionName: name)
        actionStack.add(entry: entry)
        
        // Each session can be used by only one thread, and as such we can remember the "most recent" action request
        currentActionStackEntry = entry

        // By the magic of closures we get to capture the Action Stack that the action request is part of here
        // and can terminate the correct one
        completionRequirement.addProxyCompletionHandler { outcome, completesAsync in
            // Terminate the current stack if required
            switch outcome {
                case .successWithFeatureTermination,
                     .failureWithFeatureTermination:
                    // This is threadsafe so we don't care what we're calling on
                    self.actionStackTracker.terminate(actionStack, actionRequest: request)
                default:
                    break
            }
            return outcome
        }

        // Make sure completion happens on the right queue
        completionRequirement.completionQueue = smartCallerQueue
        
        // As we are using the dispatcher, it will guarantee completion is only called on our expected queue, which should
        // match the queue we are currently on, so the completion is all threadsafe.
        let completionStatus = dispatcher.perform(request: request, completion: completionRequirement)
        return completionStatus
    }
}
