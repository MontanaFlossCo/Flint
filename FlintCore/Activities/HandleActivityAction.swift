//
//  HandleActivityAction.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is the internal action that receives an `NSUserActivity` for continuation, and if it supports Flint automatic continue,
/// will obtain an appropriate presenter and input, and perform the action.
///
/// Flint's automatic activity handling can work in one of two ways:
///
/// 1. Your action's `InputType` conforms to `ActivityCodable` and can fully marshal itself to/from userInfo used in an `NSUserActivity`
/// 2. Alternatively, if your action is URLMapped and the `InputType` conforms to `RouteParametersCodable`, Flint will
/// automatically use the default URL mapping for your action to perform the action when it is used inside an `NSUserActivity`.
///
/// Approach #1 is recommended for when you don't also need a URL mapping for an action, or you are implementing
/// a special activity such as a Siri Intent.
final class HandleActivityAction: Action {
    typealias InputType = NSUserActivity
    typealias PresenterType = PresentationRouter
    
    static let description: String = "Automatic action dispatch for incoming NSUserActivity instances published by Flint"
    
    static func perform(context: ActionContext<NSUserActivity>, presenter: PresentationRouter, completion: Action.Completion) -> Action.Completion.Status {
        // Do we need to check if activityType == CSSearchableItemActionType for spotlight invocations?
        
        // Check for Flint autoURL handling, and if so dispatch as a performIncomingURL action
        if let autoURL = context.input.userInfo?[ActivitiesFeature.autoURLUserInfoKey] as? URL {
            context.logs.development?.debug("Auto URL found: \(autoURL)")
            if let request = RoutesFeature.request(RoutesFeature.performIncomingURL) {
                var result: ActionPerformOutcome?
                
                // We need to proxy the completion, because for *this* action we need to indicate the action stack should close
                let proxyCompletion = ProxyCompletionRequirement(proxying: completion) { outcome, asyncCompletionStatus in
                    context.logs.development?.debug("Auto URL perform completed: \(outcome)")

                    let resultWithForcedStackClose = outcome.outcomeByOverridingCloseActionStack(true)
                    result = resultWithForcedStackClose
                    return resultWithForcedStackClose
                }

                let completionStatus = request.perform(input: autoURL, presenter: presenter, userInitiated: true, source: context.source, completion: proxyCompletion)

                flintUsagePrecondition(proxyCompletion.verify(completionStatus), "Action returned an invalid completion status")
                if completionStatus.isCompletingAsync {
                    return completion.willCompleteAsync()
                } else {
                    guard let result = result else {
                        flintBug("Proxied completion completed async but has no result")
                    }
                    // Complete with the actual result from the proxy
                    return completion.completedSync(result)
                }
            } else {
                context.logs.development?.error("Cannot perform automatic activity URL handling as RoutesFeature feature is disabled")
                return completion.completedSync(.failure(error: nil, closeActionStack: true))
            }
        } else {
            // Check for Flint Activities support and use performIncomingActivity instead
            if let request = ActivitiesFeature.request(ActivitiesFeature.performIncomingActivity) {
                var result: ActionPerformOutcome?
                
                let proxyCompletion = ProxyCompletionRequirement(proxying: completion) { outcome, completedAsync in
                    context.logs.development?.debug("userInfo perform completed: \(outcome)")

                    let resultWithForcedStackClose = outcome.outcomeByOverridingCloseActionStack(true)
                    result = resultWithForcedStackClose
                    return resultWithForcedStackClose
                }

                let completionStatus = request.perform(input: context.input, presenter: presenter, userInitiated: true, source: context.source, completion: proxyCompletion)
                flintUsagePrecondition(proxyCompletion.verify(completionStatus), "Action returned an invalid completion status")
                if completionStatus.isCompletingAsync {
                    return completion.willCompleteAsync()
                } else {
                    guard let result = result else {
                        flintBug("Proxied completion completed async but has no result")
                    }
                    // Complete with the actual result from the proxy
                    return completion.completedSync(result)
                }
            } else {
                context.logs.development?.error("Cannot perform automatic activity URL handling as ActivitiesFeature is disabled")
                return completion.completedSync(.failure(error: nil, closeActionStack: true))
            }
        }
    }
}

extension ActionPerformOutcome {
    func outcomeByOverridingCloseActionStack(_ shouldClose: Bool) -> ActionPerformOutcome {
        switch self {
            case .success:
                return .success(closeActionStack: shouldClose)
            case .failure(let error, _):
                return .failure(error: error, closeActionStack: shouldClose)
        }
    }
}
