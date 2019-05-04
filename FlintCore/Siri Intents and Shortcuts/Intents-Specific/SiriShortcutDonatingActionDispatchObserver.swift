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
#if canImport(Network) && os(iOS)
@available(iOS 12, *) 
class SiriShortcutDonatingActionDispatchObserver: ActionDispatchObserver {
    let loggers: ContextualLoggers
    
    init() {
        loggers = SiriIntentsFeature.logs(for: "Intent Dispatch")
    }
    
    func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>) where FeatureType : FeatureDefinition, ActionType : Action {
    }
    
    func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) where FeatureType : FeatureDefinition, ActionType : Action {
        let associatedIntents: [FlintIntent]?
        do {
            associatedIntents = try ActionType.associatedIntents(forInput: request.context.input)
        } catch let error {
            loggers.development?.error("Unable to get associated intents for \(request.context.input): \(error)")
            loggers.production?.error("Unable to get associated intents for \(request.context.input): \(error)")
            return
        }
    
        guard let intents = associatedIntents else {
            loggers.development?.debug("Action completed but did not return an intent to donate: \(request)")
            return
        }
        for intent in intents {
            if let actionRequest = IntentShortcutDonationFeature.donateShortcut.request() {
                loggers.development?.debug("Action \(ActionType.self) completed and returned an Intent to donate: \(intent)")
                actionRequest.perform(withInput: FlintIntentWrapper(intent: intent))
            } else {
                loggers.development?.debug("Action \(ActionType.self) completed and has an intent to donate but the donation feature is not enabled")
            }
        }
    }
}
#endif
