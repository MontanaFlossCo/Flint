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
public protocol IntentBackgroundAction: Action {
}

public protocol IntentAction: IntentBackgroundAction {
    associatedtype IntentType: FlintIntent
    associatedtype IntentResponseType: FlintIntentResponse

    typealias PresenterType = IntentResponsePresenter<IntentResponseType>

#if canImport(Intents)
    /// Implement this function if the Action supports a Siri Intent for Shortcuts. This is used to register
    /// a shortcut intent with Siri if you have the `IntentShortcutDonationFeature` enabled.
    @available(iOS 12, *)
    static func intent(for input: InputType) -> IntentType?

    @available(iOS 12, *)
    static func input(for intent: IntentType) -> InputType?
#endif
}

/// Set up the queue and session to use for Siri actions because these cannot use the main queue.
public extension IntentBackgroundAction {
    static var queue: DispatchQueue { return intentsQueue }
    static var defaultSession: ActionSession? { return intentActionSession }
}
