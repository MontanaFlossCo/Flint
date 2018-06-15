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
///
/// based activity handling, invokes the action specified by the URL.
final class HandleActivityAction: Action {
    typealias InputType = NSUserActivity
    typealias PresenterType = PresentationRouter
    
    static let description: String = "Automatic action dispatch for incoming NSUserActivity instances published by Flint"
    
    static func perform(with context: ActionContext<NSUserActivity>, using presenter: PresentationRouter, completion: @escaping (ActionPerformOutcome) -> Void) {
        // Do we need to check if activityType == CSSearchableItemActionType for spotlight invocations?
        
        if let autoURL = context.input.userInfo?[ActivitiesFeature.autoURLUserInfoKey] as? URL {
            context.logs.development?.debug("Auto URL found: \(autoURL)")
            if let request = RoutesFeature.request(RoutesFeature.performIncomingURL) {
                var result: ActionPerformOutcome = .failure(error: nil, closeActionStack: true)
                request.perform(using: presenter, with: autoURL, userInitiated: true, source: context.source) { outcome in
                    context.logs.development?.debug("Auto URL perform completed: \(outcome)")
                    if case .success = outcome {
                        result = .success(closeActionStack: true)
                    } else if case .failure(let error) = outcome {
                        result = .failure(error: error, closeActionStack: true)
                    }
                }
                completion(result)
            } else {
                context.logs.development?.error("Cannot perform automatic activity URL handling as RoutesFeature feature is disabled")
                completion(.failure(error: nil, closeActionStack: true))
            }
        } else {
            if let request = ActivitiesFeature.request(ActivitiesFeature.performIncomingActivity) {
                var result: ActionPerformOutcome = .failure(error: nil, closeActionStack: true)
                request.perform(using: presenter, with: context.input, userInitiated: true, source: context.source) { outcome in
                    context.logs.development?.debug("userInfo perform completed: \(outcome)")
                    if case .success = outcome {
                        result = .success(closeActionStack: true)
                    } else if case .failure(let error) = outcome {
                        result = .failure(error: error, closeActionStack: true)
                    }
                }
                completion(result)
            } else {
                context.logs.development?.error("Cannot perform automatic activity URL handling as ActivitiesFeature is disabled")
                completion(.failure(error: nil, closeActionStack: true))
            }
        }
    }
}
