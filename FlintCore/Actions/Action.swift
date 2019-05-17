//
//  Action.swift
//  FlintCore
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

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
    /// An alias for the completion type used with this action. This is a convenience to make
    /// it less verbose to conform to this protocol.
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
    associatedtype PresenterType = NoPresenter

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

    /// The session to use when calling `perform` on the action binding, to avoid having to be explicit.
    /// Most actions only make sense in the context of a single session e.g. the UI or "background".
    static var defaultSession: ActionSession? { get }

    /// If `true` this action will never be reported to the Timeline.
    /// This is useful for internal actions that are not explicitly triggered by the user.
    /// There is a default implementation provided that returns `false`.
    static var hideFromTimeline: Bool { get }

    /// Implement this static function to perform the action. You typically access `context.input` to read the input
    /// and call functions on `presenter` to update the UI.
    ///
    /// The `completion` closure must be called when the action has been performed.
    ///
    /// - param context: The action's context, which includes the `input`, logging and source information
    /// - param presenter: The presenter the action must use
    /// - param completion: The completion requirement that the action must use to indicate success or failure
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
    ///
    /// - param request: The action request that is being performed. You use the properties of this, including the
    /// `input` property of it, to return any extra attributes you'd like to be logged by your analytics system.
    ///
    /// - return: A dictionary of keys and values to be send with the analytics event, or nil if there are none
    static func analyticsAttributes<F>(forRequest request: ActionRequest<F, Self>) -> [String:Any?]?

    // MARK: User Activity - optional
    
    /// The activity types the action supports. This must contain at least one eligibility value for the
    /// activity to be` registered with the system, and the `ActivitiesFeature` must be available.
    ///
    /// Eligiblity values control whether the action is also exposed for e.g. Spotlight or Handoff. If you just want Siri
    /// proactive suggestions, use `[.perform]`.
    ///
    /// - see: `ActivitiesFeature`
    static var activityEligibility: Set<ActivityEligibility> { get }

    /// Implement this function to configure the NSUserActivity for any extra preparation required by the action.
    ///
    /// The activity will have been already populated for the action's ID and eligibility.
    /// You do not need to implement this if your feature and action support URL Routes, unless you have
    /// extra information not included in the URL that you wish to include.
    ///
    /// The `input` property on the build contains the input to the action that should be encoded into the `NSUserActivity`.
    /// Call `cancel` on the builder to veto publishing the activity at all. If the activity cannot be
    /// used due to an error and your app needs to know this, you can throw an error.
    ///
    /// - see: `ActivityBuilder`
    ///
    /// - param activity: An instance of the activity builder that you use to set up the `NSUserActivity` instance
    static func prepareActivity(_ activity: ActivityBuilder<Self>) throws

    // MARK: Siri and Intents

    /// A suggested Siri Shortcut phrase to show in the Siri UI when adding a shortcut or registering an `NSUserActivity` for
    /// this action.
    ///
    /// - note: This value is only used if your `activityEligibility` includes `.prediction`, or when your action creates
    /// an `INIntent` to donate.
    static var suggestedInvocationPhrase: String? { get }
    
#if canImport(Intents)
    /// Implement this function if the Action supports one or more Siri Intents for Shortcuts. This is used to automatically
    /// donate shortcuts with Siri if you have the `IntentShortcutDonationFeature` enabled.
    ///
    /// - param input: The input to use when creating associated intents for this action.
    ///
    /// - return: An array of intents to donate to the system for this input, or nil if there are none.
    @available(iOS 12, *)
    static func associatedIntents(forInput input: InputType) throws -> [FlintIntent]?
#endif

}


