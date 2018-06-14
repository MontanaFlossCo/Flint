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

    static func makeActivityID(forActionName name: String) -> String {
        return "\(bundleID).\(name.lowerCasedID())"
    }
    
    /// A helper function for creating an `NSUserActivity` for an action with a given inputt
    public static func createActivity<ActionType>(for action: ActionType.Type, with input: ActionType.InputType, appLink: URL? = nil) -> NSUserActivity? where ActionType: Action {
        let activityTypes = action.activityTypes
        guard activityTypes.count > 0 else {
            return nil
        }
        
        // These are the basic activity requirements
        /// !!! TODO: This should use the identifier, not the name. The name may change or be non-unique
        let activityID = makeActivityID(forActionName: action.name)
        precondition(FlintAppInfo.activityTypes.contains(activityID),
                     "The Info.plist property NSUserActivityTypes must include all activity type IDs you support. " +
                     "The ID `\(activityID)` is not there.")

        // The action can populate or veto publishing this activity by cancelling the builder passed in.
        // Introduce a new scope to prevent accidentally use of the wrong activity instance
        let builder = ActivityBuilder(activityID: activityID, activityTypes: activityTypes, appLink: appLink, input: input)
        let function: (ActivityBuilder<ActionType.InputType>) -> Void = action.prepareActivity
        let activity = builder.build(function)
        return activity
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
