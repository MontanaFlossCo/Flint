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

// Experimental Siri APIs
public let intentsQueue = DispatchQueue(label: "intents-actions")
public let intentActionSession = ActionSession(named: "Intents", userInitiatedActions: true, callerQueue: intentsQueue)

public protocol SiriResultPresenter {
    associatedtype ResponseType: INIntentResponse
    func showResult(response: ResponseType)
}

public protocol SiriIntentAction: Action {
#if canImport(Intents)
    @available(iOS 12, *)
    static func intent(for input: InputType) -> INIntent
#endif
}

public extension SiriIntentAction {
    static var queue: DispatchQueue { return intentsQueue }
    static var defaultSession: ActionSession? { return intentActionSession }
}

public extension SiriIntentAction {
#if canImport(Intents)
    @available(iOS 12, *)
    static func donateToSiri(input: InputType) {
        let intentToUse = intent(for: input)
        intentToUse.suggestedInvocationPhrase = suggestedInvocationPhrase

        let interaction = INInteraction(intent: intentToUse, response: nil)
        interaction.donate { error in
            print("Donation error: \(String(describing: error))")
        }
    }
#endif
}
