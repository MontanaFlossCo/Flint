//
//  Action.swift
//  FlintCore
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Actions that can be performed conform to this protocol to define their inputs, presenter and logic.
///
/// Actions are statically defined to avoid the mistake of storing state with them. Any state belongs in
/// the `input` passed when performing the action.
///
/// Many of these static properties have default implementations provided by a protocol extension.
///
/// - note: Action implementations *must* be final due to Swift extension requirements.
///
/// The same action can be reused in different features, so they receive all context they need when executing.
///
/// Note that actions have their own analytics ID defined statically.
public protocol Action {
    /// The InputType defines the type of value to expect as the input for the action.
    /// This provides your initial and perhaps changing state, if you want to pass it back in later.
    ///
    /// If your action requires no input you can use `NoInput`, and pass the value `.none` as input when performing.
    ///
    /// - note: Due to a Swift compiler issue, you cannot declare this as an optional type. As a result, all invocations
    /// are declared as `InputType?` so actions must always be ready to accept nil.
    ///
    /// - see: `NoInput`
    associatedtype InputType: CustomStringConvertible

    /// The type to use as the presenter (UI) for the action.
    ///
    /// This provides high level UI functions that the action can drive.
    ///
    /// You can use any type. It is better to use non-UI framework types and introduce your own cross-platform
    /// protocols instead. This makes unit testing of features and actions possible.
    ///
    /// If your action requires no UI, you can set it to `NoPresenter` and pass `nil` when calling `perform()`
    associatedtype PresenterType

    /// The name of the action, for logging and UIs
    /// There is a default implementation provided.
    static var name: String { get }

    /// The description of the action, for debug or automation UIs
    /// There is a default implementation provided.
    static var description: String { get }

    /// The queue the action should be called on. The dispatcher will ensure this is the queue used.
    ///
    /// The default value is `DispatchQueue.main`.
    ///
    /// - note: This must be a serial queue because in future we may set the context-specific loggers as a specific key
    /// on the queue. Concurrency would break this.
    static var queue: DispatchQueue { get }

    /// If `true` this action will never be reported to the Timeline.
    /// This is useful for internal actions that are not explicitly triggered by the user.
    /// There is a default implementation provided that returns `false`.
    static var hideFromTimeline: Bool { get }

    /// Implement this static function to perform the action. You typically access `context.input` to read the input
    /// and call functions on `presenter` to update the UI.
    ///
    /// The `completion` closure must be called when the action has been performed.
    ///
    /// - param context: The action's context, which includes the `input` and
    static func perform(with context: ActionContext<InputType>, using presenter: PresenterType, completion: @escaping (ActionPerformOutcome) -> Void)

    // The stuff that follows should be in a separate protocol but requires InputType so it is not possible to do this
    // in Swift 4, as we need the InputType typealias, but then there is no way to constrain the ActionDispatchObserver functions
    // to support both normal actions and activity-supporting actions.
    
    // MARK: Analytics - optional

    /// The optional ID for this action in your analytics back-end.
    /// If no value is returned (the default), no analytics tracking will occur for the action.
    static var analyticsID: String? { get }

    /// Implement this function to marshal the information about the action invocation into a dictionary for your analytics system.
    /// If you don't use analytics, you don't need to implement this.
    static func analyticsAttributes<F>(for request: ActionRequest<F, Self>) -> [String:Any?]? where F: FeatureDefinition

    // MARK: User Activity - optional
    
    /// The activity types the action supports. This must contain at least one eligibility value for the
    /// activity to be registered with the system, and the `ActivitiesFeature` must be available.
    ///
    /// Eligiblity values control whether the action is also exposed for e.g. Spotlight or Handoff. If you just want Siri
    /// proactive suggestions, use `[.perform]`.
    ///
    /// - see: `ActivitiesFeature`
    static var activityTypes: Set<ActivityEligibility> { get }

    /// Implement this function to configure the NSUserActivity for any extra preparation required by the action.
    ///
    /// The activity will have been already populated for the action's ID and eligibility.
    /// You do not need to implement this if your feature and action support URL Routes, unless you have
    /// extra information not included in the URL that you wish to include.
    ///
    /// - return: nil to veto publishing the activity at all, or return another value replace it with your own instance.
    static func prepare(activity: NSUserActivity, with input: InputType?) -> NSUserActivity?
}

/// Default implementation of the action requirements, to ease the out-of-box experience.
public extension Action {

    /// The default naming algorithm is to use the action type's name tokenized on CamelCaseBoundaries and with `Action`
    /// removed from the end. e.g. `CreateNewTweetAction` gets the name `Create New Tweet`
    static var name: String {
        let typeName = String(describing: self)
        var tokens = typeName.camelCaseToTokens()
        if tokens.last == "Action" {
            tokens.remove(at: tokens.count-1)
        }
        return tokens.joined(separator: " ")
    }

    /// The default alerts you to the fact there is no description. You should help yourself by always supplying something
    static var description: String {
        return "No description"
    }

    /// By default, all actions are included in the Timeline.
    /// Override this and return `true` if your action is not something that helps debug what the user has been doing.
    static var hideFromTimeline: Bool {
        return false
    }

    /// By default the dispatch queue that all actions are called on is `main`.
    /// They will be called synchronously if the caller is already on the same queue, and asynchronously
    /// only if the caller is not already on the same queue.
    ///
    /// - see: `ActionSession.callerQueue` because that determines which queue the action can be performed from,
    /// and the session will prevent calls from other queues. This does not have to be the same as the Action's queue.
    static var queue: DispatchQueue {
        return .main
    }

    // MARK: Analytics

    /// Default is to supply no analytics ID and no analytics event will be emitted for these actions
    static var analyticsID: String? {
        return nil
    }

    /// Default behaviour is to not provide any attributes for analytics
    static func analyticsAttributes<F>(for request: ActionRequest<F, Self>) -> [String:Any?]? where F: FeatureDefinition {
        return nil
    }

    // MARK: Activities (automatic NSUserActivity)
    
    /// By default there are no activity types, so no `NSUserActivity` will be emitted.
    static var activityTypes: Set<ActivityEligibility> {
        return []
    }

    /// The default behaviour is to return the input activity unchanged.
    ///
    /// Provide your own implementation if you need to customize the `NSUserActivity` for an Action.
    static func prepare(activity: NSUserActivity, with state: InputType?) -> NSUserActivity? {
        return activity
    }
}
