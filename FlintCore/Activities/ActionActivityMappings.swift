//
//  ActionActivityMappings.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Callback function used to invoke an action for an activity
typealias ActivityExecutor = (_ activity: NSUserActivity, _ PresentationRouter: PresentationRouter, _ source: ActionSource, _ completion: (ActionPerformOutcome) -> Void) -> ()

public struct ActivityExecutionContext {
    /// The closure that can perform the action with the supplied parameters and presentation router.
    /// This closure is used because actions have associated types and Self requirements, so the actual
    /// action is captured when the URL mapping is declared and the type is known, so we only need to
    /// call this closure and not worry about the viral generic requirements or type erasure challenges.
    let executor: ActivityExecutor
    
    /// The activity ID that was bound to the executor.
    let activityID: String
}

class ActionActivityMappings {

    /// Global internal var for all the app's mappings
    static var instance = ActionActivityMappings()

    /// Used to executue actions for incoming activities
    var executorsByActivityID: [String:ActivityExecutor] = [:]

    static let bundleID = Bundle.main.bundleIdentifier!

    /// A helper function for creating an `NSUserActivity` for an action with a given inputt
    public static func createActivity<FeatureType, ActionType>(for actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                               with input: ActionType.InputType, appLink: URL? = nil) -> NSUserActivity? {
        return createActivity(for: actionBinding.action, of: actionBinding.feature, with: input, appLink: appLink)
    }
    
    public static func createActivity<FeatureType, ActionType>(for actionBinding: ConditionalActionBinding<FeatureType, ActionType>,
                                                               with input: ActionType.InputType, appLink: URL? = nil) -> NSUserActivity? {
        return createActivity(for: actionBinding.action, of: actionBinding.feature, with: input, appLink: appLink)
    }
    
    static func createActivity<ActionType>(for action: ActionType.Type, of feature: FeatureDefinition.Type,
                                           with input: ActionType.InputType, appLink: URL? = nil) -> NSUserActivity? where ActionType: Action {
        let activityTypes = action.activityTypes
        guard activityTypes.count > 0 else {
            return nil
        }
        
        // These are the basic activity requirements
        /// !!! TODO: This should use the identifier, not the name. The name may change or be non-unique
        let activityID = ActionActivityMappings.makeActivityID(forActionNamed: action.name, of: feature)
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

    static func makeActivityID(forActionNamed actionName: String, of feature: FeatureDefinition.Type) -> String {
        return "\(bundleID).\(feature.name.lowerCasedID()).\(actionName.lowerCasedID())"
    }

    private func addMapping(for activityID: String, to actionName: String, executor: @escaping ActivityExecutor) {
        executorsByActivityID[activityID] = executor
    }
    
    /// Add a URL Mapping, with the `URLExecutor` used to actually invoke the action.
    /// - note: This mechanism is required because of the associate type requirements on `Action`
    func registerActivity<FeatureType, ActionType>(for binding: StaticActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        let activityID = ActionActivityMappings.makeActivityID(forActionNamed: binding.action.name, of: binding.feature)

        let executor: ActivityExecutor = { (activity, presentationRouter: PresentationRouter, source: ActionSource, completion: (ActionPerformOutcome) -> Void) in
            FlintInternal.logger?.debug("Executing activity \(activityID) with \(binding)")
            guard activityID == activity.activityType else {
                fatalError("Activity executor for \(activityID) invoked with wrong activity type: \(activity.activityType)")
            }
      
            do {
                let state = try ActionType.InputType.init(activityUserInfo: activity.userInfo)

                let presentationRouterResult = presentationRouter.presentation(for: binding, with: state)

                FlintInternal.urlMappingLogger?.debug("Activity executor presentation \(presentationRouterResult) received for \(binding) with state \(state)")
                switch presentationRouterResult {
                    case .appReady(let presenter):
                        binding.perform(using: presenter, with: state, userInitiated: true, source: source)
                    case .unsupported:
                        FlintInternal.urlMappingLogger?.error("No presentation for activity ID \(activity.activityType) for \(binding) - received .unsupported")
                    case .appCancelled, .userCancelled, .appPerformed:
                    break
                }
            } catch let e {
                preconditionFailure("Unable to create action state \(String(describing: ActionType.InputType.self)) from activity userInfo")
            }
        }

        addMapping(for: activityID, to: binding.action.name, executor: executor)
    }

    func registerActivity<FeatureType, ActionType>(for binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        let activityID = ActionActivityMappings.makeActivityID(forActionNamed: binding.action.name, of: binding.feature)

        let executor: ActivityExecutor = { (activity, presentationRouter: PresentationRouter, source: ActionSource, completion: (ActionPerformOutcome) -> Void) in
            FlintInternal.logger?.debug("Executing activity \(activityID) with \(binding)")
            guard activityID == activity.activityType else {
                fatalError("Activity executor for \(activityID) invoked with wrong activity type: \(activity.activityType)")
            }

            do {
                let state = try ActionType.InputType.init(activityUserInfo: activity.userInfo)

                let presentationRouterResult = presentationRouter.presentation(for: binding, with: state)

                FlintInternal.urlMappingLogger?.debug("Activity executor presentation \(presentationRouterResult) received for \(binding) with state \(state)")
                switch presentationRouterResult {
                    case .appReady(let presenter):
                        if let request = binding.request() {
                            request.perform(using: presenter, with: state, userInitiated: true, source: source)
                        }
                    case .unsupported:
                        FlintInternal.urlMappingLogger?.error("No presentation for activity ID \(activity.activityType) for \(binding) - received .unsupported")
                    case .appCancelled, .userCancelled, .appPerformed:
                    break
                }
            } catch let e {
                preconditionFailure("Unable to create action state \(String(describing: ActionType.InputType.self)) from activity userInfo")
            }
        }

        addMapping(for: activityID, to: binding.action.name, executor: executor)
    }
    /// Retrieves the action executor block, if any, for the given URL path in the specified Route scope.
    /// The executor captures the original generic Action so that it can be stored here and executed later even though
    /// `Action` has associated types.
    func actionExecutor(for activityID: String) -> ActivityExecutor? {
        return executorsByActivityID[activityID]
    }

    private func featureActionKey(for feature: FeatureDefinition.Type, action actionName: String) -> String {
        let featureName = String(describing: feature.name)
        return "\(featureName)#\(actionName)"
    }
}
