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
    
    static private var currentActivity: NSUserActivity?

    static let bundleID = Bundle.main.bundleIdentifier!

    static func perform(with context: ActionContext<InputType>, using presenter: NoPresenter, completion: @escaping (ActionPerformOutcome) -> Void) {
        let activityTypes = context.input.activityTypes
        guard activityTypes.count > 0 else {
            return completion(.success(closeActionStack: true))
        }
        
        // These are the basic activity requirements
        /// !!! TODO: This should use the identifier, not the name. The name may change or be non-unique
        let activityID = makeActivityID(forActionName: context.input.actionName)
        precondition(FlintAppInfo.activityTypes.contains(activityID),
                     "The Info.plist property NSUserActivityTypes must include all activity type IDs you support. " +
                     "The ID `\(activityID)` is not there.")

        let activity = NSUserActivity(activityType: activityID)

        activity.isEligibleForSearch = activityTypes.contains(.search)
        activity.isEligibleForHandoff = activityTypes.contains(.handoff)
        activity.isEligibleForPublicIndexing = activityTypes.contains(.publicIndexing)

// This is the only compile-time check we have available to us right now for Xcode 10 SDKs
#if swift(>=4.2)
        if #available(iOS 12, watchOS 5, *) {
            activity.isEligibleForPrediction = activityTypes.contains(.prediction)
            // Force search eligibility as this is required for prediction too
            if activity.isEligibleForPrediction {
                activity.isEligibleForSearch = true
            }
        }
#endif

        // If the action provides some extra data, use this. Note that the prepareFunction has already been
        // essentially "curried" to capture the original `input` of the action being published.
        guard let preparedActivity = context.input.prepareFunction(activity) else {
            return completion(.success(closeActionStack: true))
        }
        
        if activity.isEligibleForSearch  {
            guard let _ = activity.title else {
                preconditionFailure("Activity cannot be indexed for search without a title set")
            }
        }
        
        if let url = context.input.appLink {
            activity.addUserInfoEntries(from: [ActivitiesFeature.autoURLUserInfoKey: url])
        }
        
        var activityDebug: String = ""
        if let _ = context.logs.development?.debug {
            activityDebug = preparedActivity._detailedDebugDescription
        }
        if preparedActivity != activity {
            context.logs.development?.debug("Registering custom user activity returned by action: \(activityDebug))")
        } else {
            context.logs.development?.debug("Setting user activity: \(activityDebug)")
        }
        
        // Keep a reference to the activity
        currentActivity = preparedActivity
        preparedActivity.becomeCurrent()

        return completion(.success(closeActionStack: true))
    }

    static func makeActivityID(forActionName name: String) -> String {
        return "\(bundleID).\(name.lowerCasedID())"
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
