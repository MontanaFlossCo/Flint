//
//  IntentAction+Internal+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if os(iOS)
#if canImport(Intents)
import Intents
#endif
#endif

#if canImport(Network) && os(iOS) && !targetEnvironment(macCatalyst)
/// Common code for action bindings
@available(iOS 12, *)
internal extension IntentAction {

    /// Create an `INShortcut` instance for the given input. Use when pre-registering shortcuts with `INVoiceShortcuteCenter`
    ///
    /// This call will throw if the input fails to be converted to an intent or activity.
    ///
    @available(iOS 12, *)
    static func shortcut(withInput input: InputType) throws -> INShortcut? {
        guard let shortcutIntent = try intent(withInput: input) else {
            return nil
        }

        if shortcutIntent.suggestedInvocationPhrase == nil {
            shortcutIntent.suggestedInvocationPhrase = suggestedInvocationPhrase
        }

        if shortcutIntent.suggestedInvocationPhrase == nil {
            flintAdvisoryNotice("Creating intent shortcut for \(self) but suggestedInvocationPhrase is nil")
        }

        return INShortcut(intent: shortcutIntent)
    }

    /// Donate an intent-based shortcut to this `Action` to Siri for the given input.
    ///
    /// This call will throw if the input fails to be converted to an intent or activity.
    ///
    @available(iOS 12, *)
    static func donateToSiri(withInput input: InputType) throws {
        guard let intent = try intent(withInput: input) else {
            flintUsageError("Cannot donate intent to Siri, action type \(self) did not return an intent for input: \(input).")
        }

        if intent.suggestedInvocationPhrase == nil {
            intent.suggestedInvocationPhrase = suggestedInvocationPhrase
        }

        if intent.suggestedInvocationPhrase == nil {
            flintAdvisoryNotice("Donating intent for \(self) but suggestedInvocationPhrase is nil")
        }
        
        if let request = IntentShortcutDonationFeature.donateShortcut.request() {
            let intentWrapper = FlintIntentWrapper(intent: intent)
            request.perform(withInput: intentWrapper)
        }
    }
}
#endif
