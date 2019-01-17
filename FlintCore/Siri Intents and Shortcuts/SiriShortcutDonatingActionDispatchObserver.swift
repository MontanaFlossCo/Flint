//
//  SiriShortcutDonatingActionDispatchObserver.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 10/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This observes all action dispatch and detects actions performed that match
/// shortcut donation conventions and donates them.
class SiriShortcutDonatingActionDispatchObserver: ActionDispatchObserver {
    let loggers: ContextualLoggers
    
    init() {
        loggers = SiriFeature.logs(for: "Intent Dispatch")
    }
    
    func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>) where FeatureType : FeatureDefinition, ActionType : Action {
    }
    
    func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) where FeatureType : FeatureDefinition, ActionType : Action {
        if #available(iOS 12.0, *) {
            guard let intents = request.actionBinding.action.associatedIntents(for: request.context.input) else {
                loggers.development?.debug("Action completed but did not return an intent to donate: \(request)")
                return
            }
            for intent in intents {
                if let actionRequest = IntentShortcutDonationFeature.donateShortcut.request() {
                    loggers.development?.debug("Action \(request.actionBinding.action) completed and returned an Intent to donate: \(intent)")
                    actionRequest.perform(input: FlintIntentWrapper(intent: intent))
                } else {
                    loggers.development?.debug("Action \(request.actionBinding.action) completed and has an intent to donate but the donation feature is not enabled")
                }
            }
        }
    }
}
