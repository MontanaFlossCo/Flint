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
public let intentActionSession = ActionSession(named: "Intents", userInitiatedActions: true, callerQueue: intentsQueue)

/// The presenter type required when performing an action as a result of receiving a Siri Intent.
/// This is used in Intent extensions to perform the action and record the response to return to Siri.
public protocol IntentResultPresenter {
    func showResult(response: INIntentResponse)
}

/// Actions that can be represented as a Siri Intent must conform to this protocol.
public protocol IntentAction: Action {
}

/// Set up the queue and session to use for Siri actions because these cannot use the main queue.
public extension IntentAction {
    static var queue: DispatchQueue { return intentsQueue }
    static var defaultSession: ActionSession? { return intentActionSession }
}
