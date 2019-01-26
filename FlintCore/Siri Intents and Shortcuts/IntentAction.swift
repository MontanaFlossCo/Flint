//
//  SiriAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 18/09/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

// The queues and sessions to use for handling Intents
public let intentsQueue = DispatchQueue(label: "intents-actions")
public let intentActionSession = ActionSession(named: "Intents", userInitiatedActions: true)

/// Actions that implement a Siri Intent must conform to this protocol.
///
/// It will ensure that they use a non-main queue (because Intent extensions are called on a background thread) and
/// use an Intent-specific session for log and timeline scoping.
@available(iOS 12, *)
public protocol IntentBackgroundAction: Action {
}

#if canImport(Intents) && os(iOS)
/// Adopt this protocol when implementing an action that fulfills a Siri Intent via an Intent Extension
@available(iOS 12, *)
public protocol IntentAction: IntentBackgroundAction {
    /// The type of the `INIntent` thatt this action will implement. This is the Xcode-generated response type produced from your
    /// intent definition configuration.
    associatedtype IntentType: FlintIntent
    /// The type of the `INIntentResponse` for the `INIntent`. This is the Xcode-generated response type produced from your
    /// intent definition configuration.
    associatedtype IntentResponseType: FlintIntentResponse

    /// Automatic aliasing of the presenter to the appropriate type for Intents
    typealias PresenterType = IntentResponsePresenter<IntentResponseType>

    /// Implement this function if the Action supports a Siri Intent for Shortcuts. This is used to register
    /// a shortcut intent with Siri if you have the `IntentShortcutDonationFeature` enabled.
    /// - param input: The input instance. Read properties of this to create an instance of the intent type.
    @available(iOS 12, *)
    static func intent(for input: InputType) -> IntentType?

    /// Implement this function to create a valid input for the action from and instance of the `IntentType`, used
    /// when performing the action for an intent.
    /// - param intent: The intent instance. Read properties of this to create an instance of the input type.
    @available(iOS 12, *)
    static func input(for intent: IntentType) -> InputType?
}
#endif

/// Set up the queue and session to use for Siri actions because these cannot use the main queue.
@available(iOS 12, *)
public extension IntentBackgroundAction {
    /// Defaults to the serial queue on which intent actions will be performed
    static var queue: DispatchQueue { return intentsQueue }
    
    /// Default session for Intent actions, so that they are all grouped easily
    static var defaultSession: ActionSession? { return intentActionSession }
}
