//
//  PublishCurrentActionActivityAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import CoreSpotlight

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
        let activityID = "\(bundleID).\(context.input.actionName.lowerCasedID())"
        precondition(FlintAppInfo.activityTypes.contains(activityID),
                     "The Info.plist property NSUserActivityTypes must include all activity type IDs you support. " +
                     "The ID `\(activityID)` is not there.")

        let activity = NSUserActivity(activityType: activityID)

        activity.isEligibleForSearch = activityTypes.contains(.search)
        activity.isEligibleForHandoff = activityTypes.contains(.handoff)
        activity.isEligibleForPublicIndexing = activityTypes.contains(.publicIndexing)

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
            activityDebug = "Activity type: \(preparedActivity.activityType). Title: \(String(describing: activity.title)). UserInfo: \(String(reflecting: activity.userInfo)). Keywords: \(preparedActivity.keywords). Search? \(activity.isEligibleForSearch). Handoff? \(activity.isEligibleForHandoff). Public indexing? \(activity.isEligibleForPublicIndexing). Search attributes: \(String(reflecting: activity.contentAttributeSet))"
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

}
