//
//  IntentShortcutDonationFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/09/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

public final class IntentShortcutDonationFeature: ConditionalFeature {
    public static var description: String = "Automatic donation of Siri Intents when actions are performed"

    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOS = 12
        requirements.watchOS = 5

        requirements.runtimeEnabled()
    }
    
    /// Set this to `false` to disable automatic intent donation
#if os(iOS) || os(watchOS) || os(macOS)
    public static var isEnabled: Bool? = true
#else
    public static var isEnabled: Bool? = false
#endif

    static var donateShortcut = action(DonateShortcutIntentAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(donateShortcut)
        
        if isAvailable == true {
            // Implements Auto-Activities
            ActionSession.main.dispatcher.add(observer: SiriShortcutDonatingActionDispatchObserver())
        }
    }
}

/// This needs to detect actions performed that match shortcut donation conventions and donate them
class SiriShortcutDonatingActionDispatchObserver: ActionDispatchObserver {
    func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>) where FeatureType : FeatureDefinition, ActionType : Action {
        
    }
    
    func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) where FeatureType : FeatureDefinition, ActionType : Action {
    
    }
}

final class DonateShortcutIntentAction: UIAction {
    let description = "Donate a shortcut for the specified action, if desired"
    
    static func perform(context: ActionContext<NoInput>, presenter: Void, completion: Completion) -> Completion.Status {
        return completion.completedSync(.success)
    }
}
