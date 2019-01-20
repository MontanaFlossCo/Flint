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

/// The IntentShortcutDonation feature will automatically register shortcuts for actions
/// that support intents. Any action that returns a non-nil intent for a given input
/// will be automatically registered.
public final class IntentShortcutDonationFeature: ConditionalFeature {
    public static var description: String = "Automatic donation of Siri Intents when actions are performed"

    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.iOS = 12
        requirements.watchOS = 5

        requirements.runtimeEnabled()
    }
    
    /// Set this to `false` to disable automatic intent donation
#if os(iOS) || os(watchOS)
    public static var isEnabled: Bool? = true
#else
    public static var isEnabled: Bool? = false
#endif

#if canImport(Network) && os(iOS)
    @available(iOS 12, *)
    static var donateShortcut = action(DonateShortcutIntentAction.self)
#endif

    public static func prepare(actions: FeatureActionsBuilder) {
#if canImport(Network) && os(iOS)
        if #available(iOS 12, *) {
            actions.declare(donateShortcut)

            if isAvailable == true {
                // Implements Auto-Activities
                ActionSession.main.dispatcher.add(observer: SiriShortcutDonatingActionDispatchObserver())
            }
        }
#endif
    }
}
