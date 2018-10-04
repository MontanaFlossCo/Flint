//
//  SiriIntentsFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 24/09/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(Intents)
import Intents
#endif

/// The is the internal Flint feature for automatic dispatch of Siri Intent donation and handling.
public final class SiriIntentsFeature: ConditionalFeature, FeatureGroup {
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }
    
    public static var subfeatures: [FeatureDefinition.Type] = [
        IntentShortcutDonationFeature.self
    ]

    /// Set this to `false` to disable Flint's handling of incoming intents from `appliction:continueActivity:`
#if os(iOS) || os(watchOS) || os(macOS)
    public static var isEnabled: Bool? = true
#else
    public static var isEnabled: Bool? = false
#endif

    public static var description: String = "Siri Intent handling and continuation"

    static var handleIntent = action(DispatchIntentAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(handleIntent)
    }
}
