//
//  DefaultActionDispatcher.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/10/2017.
//  Copyright © 2017 Montana Floss Co. All rights reserved.
//

import Foundation

/// The protocol for observers of the ActionDispatcher.
///
/// Dispatch observers are called asynchronously on an arbitrary queue.
///
/// - note: Because of the user of generics, this cannot be @objc which is required if we want to use `ObserverSet`
/// because... https://bugs.swift.org/browse/SR-55
public protocol ActionDispatchObserver {
    func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>)
    func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome)
}

/// An action dispatcher is used to perform actions and perform housekeeping to enable tracking of which features
/// are active at a given time, hooking into logging and analytics etc.
///
/// Dispatchers are expected to perform actions synchronously.
///
/// If you wish to use your own implementation you must assign it to `Flint.dispatcher` at startup.
public protocol ActionDispatcher {

    /// Register an observer to e.g. perform logging or track analytics
    func add(observer: ActionDispatchObserver)

    /// Perform an implementation of a feature
    func perform<FeatureType, ActionType>(request: ActionRequest<FeatureType, ActionType>, callerQueue: SmartDispatchQueue,
                                          completion: Action.Completion) -> Action.Completion.Status
}

/// The default dispatcher implementation that provides the ability to observe when actions are performed, across sessions.
///
/// This will attempt to detect if the caller is on the queue the action expects, and avoid crashing with a `DispatchQueue.sync`
/// call when already on that queue. If the current queue is not the action's queue, it will use a `DispatchQueue.sync`.
///
/// The goal is that if the app is on the main queue, call `perform` and the dispatcher than finds the action expects
/// the `main` queue, that no queue or async thread hops occur. This prevents a "slushy" UI that is always updating
/// asynchronously, and means the caller does not have to worry about the queue they are on, and nor does the `Action`.
///
/// However, it is important to not that this mechanism (using setSpecific/getSpecific) will not currently work if the Action's
/// queue uses a `target` queue. Trivia: the `SmartDispatchQueue`
public class DefaultActionDispatcher: ActionDispatcher {
    /// The list of observers. We cannot use ObserverSet currently because of the use of generics in the protocol
    /// and the @objc requiredment of https://bugs.swift.org/browse/SR-55
    var observers = [ActionDispatchObserver]()
    let observerQueue = DispatchQueue(label: "tools.flint.DefaultActionDispatcher")
    
    public init() {
    }
    
    /// Add an observer that will get notified about action start and end events.
    /// - note: You can call this from any thread
    public func add(observer: ActionDispatchObserver) {
        observerQueue.sync {
            observers.append(observer)
        }
    }

    /// Perform the action, and track whether or not it was already completed by the time it returns,
    /// so whether sync or async, we know if `completion` should be called at some future point, so we can
    /// warn about this and maybe have a timeout in debug to catch occasions where this does not happen.
    public func perform<FeatureType, ActionType>(request: ActionRequest<FeatureType, ActionType>, callerQueue: SmartDispatchQueue,
                                                 completion: Action.Completion) -> Action.Completion.Status {
        begin(request: request)

        // The action does *not* have to complete synchronously. We watch out for the cases where it doesn't and
        // log this for now. In future we will have a new outcome value indicating `completingAsynchronously`.
        let action = request.actionBinding.action
        let smartActionQueue = SmartDispatchQueue(queue: action.queue, owner: self)
        var performStatus: Action.Completion.Status?
        
        // Here we synchronously call the action on the queue it has requested, and we pass a completion object in
        // that will tell us if it performed synchronously or not. The caller does not care so much, but we do
        // for safety purposes and tracking in future.
        smartActionQueue.sync {
            // Proxy the completion so we can ensure it is called on the correct queue
            /// !!! TODO: ProxyCompletion needs to take the queue on which original completion must be called
            let dispatcherCompletion = ProxyCompletionRequirement(proxying: completion, proxyCompletionHandler: { [weak self] outcome, completedAsync -> ActionPerformOutcome in
                guard let strongSelf = self else {
                    return outcome
                }
                
                // Track completion
                strongSelf.complete(request: request, outcome: outcome)
                return outcome
            })

            // Perform the action and get the immediate status of it
            let status = action.perform(context: request.context,
                                        presenter: request.presenter,
                                        completion: dispatcherCompletion)
            performStatus = status
            flintUsagePrecondition(dispatcherCompletion.verify(status), "Action returned an invalid completion status")
        }

        guard let status = performStatus else {
            flintBug("We must always have a valid perform status")
        }
        if status.isCompletingAsync {
            // If it was async, we'll log this for now. In future in dev mode maybe we'll add a timer of say 10s
            // and then log another warning if we didn't hear back from the action.
            request.context.logs.development?.debug("Action indicated it will call completion asynchronously")
        }
        return status
    }

    func begin<FeatureType, ActionType>(request: ActionRequest<FeatureType, ActionType>) {
        observerQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            for observer in strongSelf.observers {
                observer.actionWillBegin(request)
            }
        }
    }

    private func complete<FeatureType, ActionType>(request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) {
        observerQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            for observer in strongSelf.observers {
                observer.actionDidComplete(request, outcome: outcome)
            }
        }
    }
}
