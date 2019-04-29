//
//  VerifiedActionBinding+iOS+Extensions.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 09/11/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import UIKit
#if os(iOS)
#if canImport(Intents)
import Intents
#endif
#endif

// Workaround for inability to compile against just iOS 12+, using the new "Network" framework as an indicator
#if canImport(Network) && os(iOS)
extension VerifiedActionBinding {

    /// Call to invoke the system "Add Voice Shortcut" view controller for the given input to the conditionally-available
    /// action represented by this action request. The action must support creating an `NSUserActivity` using Flint's Activities conventions.
    ///
    /// This will create a shortcut that invokes the activity created for the `Action`'s.
    /// If the `Action` does not support `Activities`, this will fail.
    ///
    /// - param input: The input to pass to the action when it is later invoked from the Siri Shortcut by the user.
    /// - param presenter: The `UIViewController` to use to present the view controller
    @available(iOS 12, *)
    public func addVoiceShortcut(input: ActionType.InputType, presenter: UIViewController, completion: @escaping (_ result: AddVoiceShortcutResult) -> Void) {
        VoiceShortcuts.addVoiceShortcut(action: ActionType.self, feature: FeatureType.self, input: input, presenter: presenter, completion: completion)
    }
}

@available(iOS 12, *)
extension VerifiedActionBinding where ActionType: IntentAction {
    public func perform(intent: ActionType.IntentType, completion: @escaping (ActionType.IntentResponseType) -> Void) throws -> MappedActionResult {
        let presenter = IntentResponsePresenter(completion: completion)
        return try perform(intent: intent, presenter: presenter)
    }
    
    public func perform(intent: ActionType.IntentType, presenter: ActionType.PresenterType) throws -> MappedActionResult {
        /// !!! TODO: We probably need a Result<T> here as nil could be valid
        guard let inputFromIntent = try ActionType.input(from: intent) else {
            flintUsageError("Failed to create input from intent \(intent)")
        }

        var syncOutcome: ActionPerformOutcome?
        let completion = Action.Completion(queue: nil) { (outcome, wasAsync) in
            FlintInternal.logger?.debug("Intent perform outcome: \(outcome) wasAsync: \(wasAsync)");
            syncOutcome = outcome
        }

        let status: Action.Completion.Status = perform(input: inputFromIntent,
                                                       presenter: presenter,
                                                       userInitiated: true,
                                                       source: .intent,
                                                       completion: completion)

        if status.isCompletingAsync {
            return .completingAsync
        }
        
        guard let outcome = syncOutcome else {
            flintBug("We should have a sync outcome by now");
        }

        return .init(outcome: outcome)
    }

    /// Call to invoke the system "Add Voice Shortcut" view controller for the given input to the conditionally-available
    /// action represented by this action request. The action must support creating an `INIntent` for a custom intent extension
    /// to be invoked.
    ///
    /// This will create a shortcut that invokes the `INIntent` returned by the `Action`'s `intent(input:)` function.
    /// If that function returns nil (or is not defined by your `Action`), it will attempt to create an `NSUserActivity`
    /// for the `Action` and instead use that. If the `Action` does not support `Activities`, this will fail.
    ///
    /// - param input: The input to pass to the action when it is later invoked from the Siri Shortcut by the user.
    /// - param presenter: The `UIViewController` to use to present the view controller
    ///
    /// - note: This variant exists for the specialisation that will call `intent(input:)` on the Action to create an
    /// an intent for the shortcut.
    @available(iOS 12, *)
    public func addVoiceShortcut(input: ActionType.InputType,
                                 presenter: UIViewController,
                                 completion: @escaping (_ result: AddVoiceShortcutResult) -> Void) throws {
        try VoiceShortcuts.addVoiceShortcut(action: ActionType.self,
                                        feature: FeatureType.self,
                                        input: input,
                                        presenter: presenter,
                                        completion: completion)
    }

    @available(iOS 12, *)
    public func editVoiceShortcut(_ shortcut: INVoiceShortcut,
                                  presenter: UIViewController,
                                  completion: @escaping (_ result: EditVoiceShortcutResult) -> Void) {
        VoiceShortcuts.editVoiceShortcut(shortcut,
                                         presenter: presenter,
                                         completion: completion)
    }

    /// Create an `INShortcut` instance for the given input. Use when pre-registering shortcuts with `INVoiceShortcuteCenter`
    @available(iOS 12, *)
    public func shortcut(input: ActionType.InputType) throws -> INShortcut? {
        return try ActionType.shortcut(input: input)
    }

    /// Donate an intent-based shortcut to this `Action` to Siri for the given input.
    @available(iOS 12, *)
    public func donateToSiri(input: ActionType.InputType) throws {
        try ActionType.donateToSiri(input: input)
    }
}

#endif
