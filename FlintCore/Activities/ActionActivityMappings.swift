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

/// A class that creates and stores the mappings from NSUserActivity activity type IDs to actions and the code
/// to perform them when the activity is received.
///
/// This mechanism is required so that we can reverse from the activity ID to something that has erased the type information
/// about the Action itself, so that we can instantiate and perform it without knowing at compile time what we will be
/// receiving as input.
class ActionActivityMappings {

    /// Global internal var for all the app's mappings
    static var instance = ActionActivityMappings()

    /// Used to executue actions for incoming activities
    var executorsByActivityID: [String:ActivityExecutor] = [:]

    static let bundleID = Bundle.main.bundleIdentifier!

    /// A helper function for creating an `NSUserActivity` that will invoke an action with a given input when received
    /// at a later point by the app.
    ///
    /// - param actionBinding: The action binding that the activity should invoke
    /// - param input: The action binding that the activity should invoke
    /// - param appLink: The optional app URL mapping for the action. Used for auto-continue of activities that are URL mapped,
    /// but only if their inputs are not `ActivityCodable`. Inputs that conform to this are always encoded as activities
    /// using `userInfo` and `activityType`.
    public static func createActivity<FeatureType, ActionType>(for actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                               with input: ActionType.InputType, appLink: URL? = nil) -> NSUserActivity? {
        return createActivity(for: actionBinding.action, of: actionBinding.feature, with: input, appLink: appLink)
    }
    
    /// A helper function for creating an `NSUserActivity` that will invoke an action with a given input when received
    /// at a later point by the app.
    ///
    /// - param actionBinding: The action binding that the activity should invoke
    /// - param input: The action binding that the activity should invoke
    /// - param appLink: The optional app URL mapping for the action. Used for auto-continue of activities that are URL mapped,
    /// but only if their inputs are not `ActivityCodable`. Inputs that conform to this are always encoded as activities
    /// using `userInfo` and `activityType`.
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
        if !FlintAppInfo.activityTypes.contains(activityID) {
            fatalError("The Info.plist property NSUserActivityTypes must include all activity type IDs you support. " +
                "The ID `\(activityID)` is not there.")
        }

        // The action can populate or veto publishing this activity by cancelling the builder passed in.
        // Introduce a new scope to prevent accidentally use of the wrong activity instance
        let builder = ActivityBuilder(activityID: activityID, activityTypes: activityTypes, appLink: appLink, input: input)
        let function: (ActivityBuilder<ActionType.InputType>) -> Void = action.prepareActivity
        let activity = builder.build(function)
        return activity
    }

    /// Creates the automatic `activityType` ID for activities, unique for this app, feature and action combination.
    static func makeActivityID(forActionNamed actionName: String, of feature: FeatureDefinition.Type) -> String {
        return "\(bundleID).\(feature.name.lowerCasedID()).\(actionName.lowerCasedID())"
    }

    private func addMapping(for activityID: String, to actionName: String, executor: @escaping ActivityExecutor) {
        FlintInternal.logger?.debug("Adding activity mapping for \(activityID) to \(actionName)")
        executorsByActivityID[activityID] = executor
    }
    
    /// Adds a mapping from an `activityType` ID to a feature/action binding.
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
            } catch ActivityCodableError.missingKeys(let keys) {
                fatalError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self).self, userInfo values are missing for keys: \(keys)")
            } catch ActivityCodableError.invalidValues(let keys) {
                fatalError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self), userInfo values are invalid for keys: \(keys)")
            } catch {
                fatalError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self): \(error)")
            }
        }

        addMapping(for: activityID, to: binding.action.name, executor: executor)
    }

    /// Adds a mapping from an `activityType` ID to a conditional feature/action binding.
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
            } catch ActivityCodableError.missingKeys(let keys) {
                fatalError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self), userInfo values are missing for keys: \(keys)")
            } catch ActivityCodableError.invalidValues(let keys) {
                fatalError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self), userInfo values are invalid for keys: \(keys)")
            } catch {
                fatalError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self): \(error)")
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
