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
        if outcome.isSuccess {
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

        var appLink: URL? = nil
        var encodable: RouteParametersEncodable? = nil

        // This is a hideous workaround for the fact we cannot tell if `InputType` is an Optional or not, as
        // well as test it for `RouteParametersEncodable` conformance.
        // e.g. for `nil` we always use `[:]` for route args, so we can still create URLs to actions with nil inputs,
        // but for non-nil we can ask any value wrapped in the optional if it conforms
        if input is FlintOptionalProtocol {
            if (input as! FlintOptionalProtocol).isNil {
                encodable = EmptyRouteParametersEncodable()
            }
        }
        if encodable == nil {
            if let encodableInput = input as? RouteParametersEncodable {
                encodable = encodableInput
            }
        }
        
        if let validEncodable = encodable {
            if let linkCreator = Flint.linkCreator {
                appLink = linkCreator.appLink(to: actionRequest.actionBinding, with: validEncodable)
            } else {
                if !(input is ActivityCodable) {
                    flintUsageError("Input type \(type(of: input)) for action \(action.name) is not ActivityCodable, and " +
                        "there is no Flint.linkCreator specified (are you missing a default custom URL scheme?). " +
                        "It will not be possible to continue this activity later.")
                }
            }
        }
        
        // Create the lazy function that will create the activity on demand
        let prepareActivityWrapper = { () -> NSUserActivity? in
            return actionRequest.actionBinding.activity(for: input, withURL: appLink)
        }

        let publishState = PublishActivityRequest(actionName: action.name,
                                                feature: actionRequest.actionBinding.feature,
                                                activityCreator: prepareActivityWrapper,
                                                appLink: appLink)
        DispatchQueue.main.async {
            publishRequest.perform(input: publishState, presenter: NoPresenter(), userInitiated: false, source: .application)
        }
    }
}

private class EmptyRouteParametersEncodable: RouteParametersEncodable {
    func encodeAsRouteParameters(for mapping: URLMapping) -> RouteParameters? {
        return [:]
    }
}

