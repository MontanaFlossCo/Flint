//
//  ActivityActionDispatchObserver.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An `ActionDispatchObserver` implementation that will use the `publishCurrentActionActivity` action of `ActivitiesFeature`
/// to automatically publish an `NSUserActivity` for what the user is currently doing.
///
/// - see: `ActivitiesFeature`
public class ActivityActionDispatchObserver: ActionDispatchObserver {

    public func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>) {
    }

    public func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) {
        if case .success(_) = outcome {
            if request.actionBinding.action.activityTypes.count > 0 {
                registerUserActivity(for: request)
            }
        }
    }

    /// Called internally to register a new `NSUserActivity` for an action request.
    ///
    /// Feature Actions can implement `actionActivity(for:)` to return the basic info required, or nil if no activity at all should
    /// be registered (this is the default, via the protocol extension on `Action`).
    ///
    /// For advanced usage with full control of the `NSUserActivity` instance the feature action can implement
    /// `userActivity(for:)` and return an instance. The default implementation from the protocol extension returns
    /// nil. Returning non-nil from that function will result in a call to `actionActivity(for:)`.
    func registerUserActivity<FeatureType, ActionType>(for actionRequest: ActionRequest<FeatureType, ActionType>) {
        // Don't recurse into the activity actions
        guard actionRequest.actionBinding.feature != ActivitiesFeature.self else {
            return
        }
        
        guard let publishRequest = ActivitiesFeature.publishCurrentActionActivity.request() else {
            return
        }
        
        // Extract everything the action needs from the generic action request, as we cannot retain the type
        // information as we pass this forward to the action
        let action = actionRequest.actionBinding.action
        let input = actionRequest.context.input

        let prepareWrapper = { (activity: NSUserActivity) -> NSUserActivity? in
            return action.prepare(activity: activity, with: input)
        }
        let activityTypes = action.activityTypes
        var appLink: URL? = nil
        if let encodable = input as? QueryParametersEncodable {
            let queryParameters = encodable.encodeAsQueryParameters()
            appLink = Flint.linkCreator?.appLink(to: actionRequest.actionBinding, with: queryParameters)
        }
        
        let publishState = PublishActivityRequest(actionName: action.name,
                                                feature: actionRequest.actionBinding.feature,
                                                prepareFunction: prepareWrapper,
                                                activityTypes: activityTypes,
                                                appLink: appLink)
        DispatchQueue.main.async {
            publishRequest.perform(using: NoPresenter(), with: publishState, userInitiated: false, source: .application)
        }
    }
}

