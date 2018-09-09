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
    typealias Completion = CompletionRequirement<ActionPerformOutcome>
    
    /// The InputType defines the type of value to expect as the input for the action.
    /// This provides your initial and perhaps changing state, if you want to pass it back in later.
    ///
    /// If your action requires no input you can use `NoInput`, and parameter when performing.
    ///
    /// - note: Due to a Swift compiler issue, you cannot declare this as an optional type. As a result, all invocations
    /// are declared as `InputType?` so actions must always be ready to accept nil.
    ///
    /// - see: `NoInput`
    associatedtype InputType: FlintLoggable = NoInput

    /// The type to use as the presenter (UI) for the action.
    ///
    /// This provides high level UI functions that the action can drive.
    ///
    /// You can use any type. It is better to use non-UI framework types and introduce your own cross-platform
    /// protocols instead. This makes unit testing of features and actions possible.
    ///
    /// If your action requires no UI, you can set it to `NoPresenter` and omit the presenter when calling `perform()`
    associatedtype PresenterType  = NoPresenter

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
    static func perform(context: ActionContext<InputType>, presenter: PresenterType, completion: Completion) -> Completion.Status

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
    /// activity to be` registered with the system, and the `ActivitiesFeature` must be available.
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
    /// Call `cancel` on the builder to veto publishing the activity at all.
    ///
    /// - see: `ActivityBuilder`
    static func prepareActivity(_ activity: ActivityBuilder<Self>)

    // MARK: Siri and Intents

    /// A suggested Siri Shortcut phrase to show in the Siri UI when adding a shortcut
    static var suggestedInvocationPhrase: String? { get }
}
