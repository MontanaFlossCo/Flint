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

    public static var description: String = "Automatic donation of Siri Intents"

    static var donateShortcut = action(DonateShortcutIntentAction.self)

    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(donateShortcut)
        
        if isAvailable == true {
            // Implements Auto-Activities
            ActionSession.main.dispatcher.add(observer: SiriShortcutDonatingActionDispatchObserver())
        }
    }
}

class SiriShortcutDonatingActionDispatchObserver: ActionDispatchObserver {

}

final class DonateShortcutIntentAction: UIAction {

}
