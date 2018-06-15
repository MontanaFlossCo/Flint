//
//  HandleActivityAction.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is the internal action that receives an `NSUserActivity` for continuation, and if it supports Flint automatic URL
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
                request.perform(using: presenter, with: autoURL, userInitiated: true, source: context.source) { outcome in
                    context.logs.development?.debug("Auto URL perform completed: \(outcome)")
                }
                return completion(.success(closeActionStack: true))
            } else {
                context.logs.development?.error("Cannot perform automatic activity URL handling as Deep Linking feature is disabled")
                return completion(.failure(error: nil, closeActionStack: true))
            }
        } else {
            if let request = ActivitiesFeature.request(ActivitiesFeature.performIncomingActivity) {
                request.perform(using: presenter, with: context.input, userInitiated: true, source: context.source) { outcome in
                    context.logs.development?.debug("userInfo perform completed: \(outcome)")
                }
                return completion(.success(closeActionStack: true))
            } else {
                context.logs.development?.error("Cannot perform automatic activity URL handling as Deep Linking feature is disabled")
                return completion(.failure(error: nil, closeActionStack: true))
            }
        }
    }
}
