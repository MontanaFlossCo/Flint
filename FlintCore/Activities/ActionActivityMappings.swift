//
//  ActionActivityMappings.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Callback function used to invoke an action for an activity.
///
/// - note: These executors must always be called on the main thread, and they will complete synchronously.
/// This is why they return the outcome and don't have `completion`.
typealias ActivityExecutor = (_ activity: NSUserActivity, _ PresentationRouter: PresentationRouter, _ source: ActionSource) -> ActionPerformOutcome

public enum ActivityExecutionError: Error {
    case noPresenter
    case appCancelled
    case userCancelled
    case appAlreadyPerformed
    case featureNotAvailable
}

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
    static func createActivity<FeatureType, ActionType>(for actionBinding: StaticActionBinding<FeatureType, ActionType>,
                                                        with input: ActionType.InputType,
                                                        appLink: URL? = nil) throws -> NSUserActivity? {
        return try createActivity(for: ActionType.self,
                                  of: FeatureType.self,
                                  with: input,
                                  appLink: appLink)
    }
    
    /// A helper function for creating an `NSUserActivity` that will invoke an action with a given input when received
    /// at a later point by the app.
    ///
    /// - param actionBinding: The action binding that the activity should invoke
    /// - param input: The action binding that the activity should invoke
    /// - param appLink: The optional app URL mapping for the action. Used for auto-continue of activities that are URL mapped,
    /// but only if their inputs are not `ActivityCodable`. Inputs that conform to this are always encoded as activities
    /// using `userInfo` and `activityType`.
    static func createActivity<FeatureType, ActionType>(for actionBinding: ConditionalActionBinding<FeatureType, ActionType>,
                                                        with input: ActionType.InputType,
                                                        appLink: URL? = nil) throws -> NSUserActivity? {
        return try createActivity(for: ActionType.self, of: FeatureType.self, with: input, appLink: appLink)
    }
    
    /// Interfnal function to create the activity.
    static func createActivity<ActionType>(for action: ActionType.Type, of feature: FeatureDefinition.Type,
                                           with input: ActionType.InputType, appLink: URL? = nil) throws -> NSUserActivity? where ActionType: Action {
        let activityEligibility = action.activityEligibility
        guard activityEligibility.count > 0 else {
            return nil
        }
        
        // These are the basic activity requirements
        /// !!! TODO: This should use the identifier, not the name. The name may change or be non-unique
        let activityID = ActionActivityMappings.makeActivityID(forActionNamed: action.name, of: feature)

        flintAdvisoryPrecondition(FlintAppInfo.activityTypes.contains(activityID), "The Info.plist property NSUserActivityTypes must include all activity type IDs you support. " +
            "The ID `\(activityID)` is not there.")

        // The action can populate or veto publishing this activity by cancelling the builder passed in.
        // Introduce a new scope to prevent accidentally use of the wrong activity instance
        let builder = ActivityBuilder(activityID: activityID, action: action, input: input, appLink: appLink)
        let function: (ActivityBuilder<ActionType>) -> Void = action.prepareActivity
        let activity = try builder.build(function)
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
        guard ActionType.activityEligibility.count > 0 else {
            FlintInternal.logger?.debug("Not registering activity for \(ActionType.self), no activity types set.")
            return
        }

        let activityID = ActionActivityMappings.makeActivityID(forActionNamed: ActionType.name, of: FeatureType.self)

        let executor: ActivityExecutor = { (activity, presentationRouter: PresentationRouter, source: ActionSource) -> ActionPerformOutcome in
            FlintInternal.logger?.debug("Executing activity \(activityID) with \(binding)")
            guard activityID == activity.activityType else {
                flintBug("Activity executor for \(activityID) invoked with wrong activity type: \(activity.activityType)")
            }
      
            do {
                let input = try ActionType.InputType.init(activityUserInfo: activity.userInfo)

                let presentationRouterResult = presentationRouter.presentation(for: binding, input: input)
                if case let .appReady(presenter) = presentationRouterResult {
                    var outcome: ActionPerformOutcome?
                    
                    let completion = Action.Completion(queue: nil, completionHandler: { performOutcome, completedAsync in
                        outcome = performOutcome
                    })
                    let result = binding.perform(withInput: input, presenter: presenter, userInitiated: true, source: source, completion: completion)
                    flintUsagePrecondition(completion.verify(result), "Completion returned a result from a different completion object")
                    flintUsagePrecondition(!result.isCompletingAsync, "Activities can only invoke actions that perform synchronous completion")
                    guard let performOutcome = outcome else {
                        flintBug("Action outcome was not captured")
                    }
                    return performOutcome
                } else {
                    return ActionActivityMappings.failedPresentationResultToActionPerformOutcome(presentationRouterResult)
                }
            } catch ActivityCodableError.missingKeys(let keys) {
                flintUsageError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self).self, userInfo values are missing for keys: \(keys)")
            } catch ActivityCodableError.invalidValues(let keys) {
                flintUsageError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self), userInfo values are invalid for keys: \(keys)")
            } catch {
                flintUsageError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self): \(error)")
            }
        }

        addMapping(for: activityID, to: ActionType.name, executor: executor)
    }

    /// Adds a mapping from an `activityType` ID to a conditional feature/action binding.
    func registerActivity<FeatureType, ActionType>(for binding: ConditionalActionBinding<FeatureType, ActionType>) where ActionType.InputType: ActivityCodable {
        guard ActionType.activityEligibility.count > 0 else {
            FlintInternal.logger?.debug("Not registering activity for \(ActionType.self), no activity types set.")
            return
        }
        
        let activityID = ActionActivityMappings.makeActivityID(forActionNamed: ActionType.name, of: FeatureType.self)

        let executor: ActivityExecutor = { (activity, presentationRouter: PresentationRouter, source: ActionSource) -> ActionPerformOutcome in
            FlintInternal.logger?.debug("Executing activity \(activityID) with \(binding)")
            guard activityID == activity.activityType else {
                flintBug("Activity executor for \(activityID) invoked with wrong activity type: \(activity.activityType)")
            }

            do {
                let input = try ActionType.InputType.init(activityUserInfo: activity.userInfo)

                let presentationRouterResult = presentationRouter.presentation(for: binding, input: input)
                if case let .appReady(presenter) = presentationRouterResult {
                    if let request = binding.request() {
                        var outcome: ActionPerformOutcome?
                        
                        let completion = Action.Completion(queue: nil, completionHandler: { performOutcome, completedAsync in
                            outcome = performOutcome
                        })
    
                        let result = request.perform(withInput: input, presenter: presenter, userInitiated: true, source: source, completion: completion)
                        flintUsagePrecondition(completion.verify(result), "Completion returned a result from a different completion object")
                        flintUsagePrecondition(!result.isCompletingAsync, "Activities can only invoke actions that perform synchronous completion")
                        guard let performOutcome = outcome else {
                            flintBug("Action outcome was not captured")
                        }
                        return performOutcome
                    } else {
                        return ActionPerformOutcome.failureWithFeatureTermination(error: ActivityExecutionError.featureNotAvailable)
                    }
                } else {
                    return ActionActivityMappings.failedPresentationResultToActionPerformOutcome(presentationRouterResult)
                }
            } catch ActivityCodableError.missingKeys(let keys) {
                flintUsageError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self), userInfo values are missing for keys: \(keys)")
            } catch ActivityCodableError.invalidValues(let keys) {
                flintUsageError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self), userInfo values are invalid for keys: \(keys)")
            } catch {
                flintUsageError("Unable to create input for action \(ActionType.self) input type \(ActionType.InputType.self): \(error)")
            }
        }

        addMapping(for: activityID, to: ActionType.name, executor: executor)
    }

    static func failedPresentationResultToActionPerformOutcome<T>(_ result: PresentationResult<T>) -> ActionPerformOutcome {
        FlintInternal.urlMappingLogger?.debug("Activity executor presentation \(result) received")
        switch result {
            case .unsupported:
                FlintInternal.urlMappingLogger?.error("No presentation for activity - received .unsupported")
                return .failureWithFeatureTermination(error: ActivityExecutionError.noPresenter)
            case .appCancelled:
                return .failureWithFeatureTermination(error: ActivityExecutionError.appCancelled)
            case .userCancelled:
                return .failureWithFeatureTermination(error: ActivityExecutionError.userCancelled)
            case .appPerformed:
                return .failureWithFeatureTermination(error: ActivityExecutionError.appAlreadyPerformed)
            case .appReady:
                flintBug("App is ready to present UI, this state is not supported")
        }
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
