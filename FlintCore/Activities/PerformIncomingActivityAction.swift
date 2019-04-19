//
//  PerformIncomingActivityAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//
import Foundation

/// Performs the action associated with the activityID and userInfo of an `NSUserActivity`
final public class PerformIncomingActivityAction: UIAction {
    public typealias InputType = NSUserActivity
    public typealias PresenterType = PresentationRouter
    
    public static var description: String = "Perform the action associated with the input activity type"

    public enum ActivityTypeError: Error {
        case noActivityTypeMappingFound
    }
    
    /// Attempt to perform the action associated with this activity.
    ///
    /// The completion outcome will fail with an error if the activity does not map to anything
    /// that Flint knows about using the `activityType`
    public static func perform(context: ActionContext<NSUserActivity>, presenter: PresentationRouter, completion: Action.Completion) -> Action.Completion.Status {
        context.logs.development?.debug("Finding action executor for activity: \(context.input.activityType), userInfo \(String(describing: context.input.userInfo))")
        
        if let executor = ActionActivityMappings.instance.actionExecutor(for: context.input.activityType) {
            context.logs.development?.debug("Executing action with userInfo: \(String(describing: context.input.userInfo))")
            let result = executor(context.input, presenter, context.source)
            return completion.completedSync(result)
        } else {
            context.logs.development?.error("Couldn't get executor for activity: \(context.input.activityType)")
            return completion.completedSync(.failureWithFeatureTermination(error: ActivityTypeError.noActivityTypeMappingFound))
        }
        
    }
}
