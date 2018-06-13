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

        var activity = NSUserActivity(activityType: activityID)

        activity.isEligibleForSearch = activityTypes.contains(.search)
        activity.isEligibleForHandoff = activityTypes.contains(.handoff)
        activity.isEligibleForPublicIndexing = activityTypes.contains(.publicIndexing)

// This is the only compile-time check we have available to us right now for Xcode 10 SDKs, that doesn't
// require raising the language level to Swift 4.2 in the target.
#if canImport(Network)
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
        // The action can veto publishing this activity by returning nil.
        
        // Introduce a new scope to prevent accidentaly use of the wrong activity instance
        do {
            guard let preparedActivity = context.input.prepareFunction(activity) else {
                return completion(.success(closeActionStack: true))
            }
            activity = preparedActivity
        }
        
        // Put in the auto link, if set and part of a URLMapped feature
        if let url = context.input.appLink {
            activity.addUserInfoEntries(from: [ActivitiesFeature.autoURLUserInfoKey: url])
        }
        
        // Apply sanity checks to the generated activity
        /// !!! TODO: Add #if DEBUG or similar around these, once we establish how we are doing that.
        
        // Check 1: Check there is a title
        if activity.isEligibleForSearch || activity.isEligibleForHandoff  {
            guard let _ = activity.title else {
                preconditionFailure("Activity cannot be indexed for search without a title set")
            }
        }

        // Check 2: If there are required userInfo keys, make sure there's a value for every key
        if let foundRequiredKeys = activity.requiredUserInfoKeys, let userInfo = activity.userInfo {
            let infoKeys = Set(userInfo.keys)
            let missingKeys = foundRequiredKeys.filter { !infoKeys.contains($0) }
            guard missingKeys.count == 0 else {
                fatalError("Action \(context.input.actionName) supplies userInfo in prepareActivity() but does not define all the keys required by requiredUserInfoKeys, missing values for: \(missingKeys)")
            }
        }
        
        var activityDebug: String = ""
        if let _ = context.logs.development?.debug {
            activityDebug = activity._detailedDebugDescription
        }

        context.logs.development?.debug("Setting user activity: \(activityDebug)")
        
        // Keep a reference to the activity
        currentActivity = activity

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
