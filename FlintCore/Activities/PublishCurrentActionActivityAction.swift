//
//  PublishCurrentActionActivityAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

/// This internal action is used to auto-publish `NSUserActivity` when an action is performed.
///
/// If the action has a Route defined in its `URLMapped` Feature, it will use this URL to automatically perform it again
/// when the activity is passed back to the application.
///
/// Actions can customise how their activity is created by implementing the `prepare` function.
final class PublishCurrentActionActivityAction: Action {
    typealias InputType = PublishActivityRequest
    typealias PresenterType = NoPresenter
    
    static let description: String = "Automatic publishing of NSUserActivity for actions with activityEligibility set"
    
    static private var currentActivity: NSUserActivity? {
        didSet {
            if let previousActivity = oldValue {
                previousActivity.resignCurrent()
            }
        
            currentActivity?.becomeCurrent()
        }
    }

    static func perform(with context: ActionContext<InputType>, using presenter: NoPresenter, completion: @escaping (ActionPerformOutcome) -> Void) {
        if let activity = context.input.activityCreator() {
            var activityDebug: String = ""
            if let _ = context.logs.development?.debug {
                activityDebug = activity._detailedDebugDescription
            }

            context.logs.development?.debug("Setting user activity: \(activityDebug)")
            
            // Keep a reference to the activity
            currentActivity = activity
        }
        
        return completion(.success(closeActionStack: true))
    }
}

extension NSUserActivity {
    var _detailedDebugDescription: String {
        var result = "Activity type: \(activityType), "
        result.append("Title: \(String(describing: title)), ")
        result.append("UserInfo: \(String(reflecting: userInfo)), ")
        result.append("Keywords: \(keywords), ")
        result.append("Search? \(isEligibleForSearch), ")
        result.append("Handoff? \(isEligibleForHandoff), ")
        result.append("Public indexing? \(isEligibleForPublicIndexing)")
#if os(iOS) || os(macOS)
        result.append(", Search attributes: \(String(reflecting: contentAttributeSet))")
#endif
        return result
    }
}
