//
//  VoiceShortcuts.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 17/01/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

#if os(iOS)
#if canImport(IntentsUI)
import UIKit
import Intents
import IntentsUI
#endif
#endif

// Workaround for inability to compile against just iOS 12+, using the new "Network" framework as an indicator
#if canImport(Network) && os(iOS)

/// Call to invoke the system "Add Voice Shortcut" view controller for the given input to the action represented.
/// by this action and feature pair. This is an internal function for code reuse and consistency. It must not be public.
///
/// - note: Currently only actions that support NSUserActivity by opting in with `activityEligibility` are supported.
///
/// - param action: The type of the action to invoke with the shortcut
/// - param feature: The type of the feature to which the action belongs
/// - param input: The input to pass to the action when it is later invoked from the Siri Shortcut by the user.
/// - param presenter: The `UIViewController` to use to present the view controller
class VoiceShortcuts {
    @available(iOS 12, *)
    static func addVoiceShortcut<ActionType, FeatureType>(action: ActionType.Type, feature: FeatureType.Type, for input: ActionType.InputType, presenter: UIViewController) where ActionType: Action, FeatureType: FeatureDefinition {
        let shortcut: INShortcut
        if let intent = ActionType.intent(for: input) {
            guard let intentShortcut = INShortcut(intent: intent) else {
                flintUsageError("The action \(action) on feature \(feature) returned an INIntent that is not valid for creating shortcuts: \(intent)")
            }
            shortcut = intentShortcut
        } else {
            guard let activity = ActionActivityMappings.createActivity(for: action, of: feature, with: input, appLink: nil) else {
                flintUsageError("The action \(action) on feature \(feature) did not return an activity for the input \(input)")
            }
            shortcut = INShortcut(userActivity: activity)
        }
        AddVoiceShortcutCoordinator.shared.show(for: shortcut, with: presenter)
    }
}

/// Internal type to handle delegation of the Add Voice Shortcut UI.
@available(iOS 12, *)
@objc internal class AddVoiceShortcutCoordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    static let shared = AddVoiceShortcutCoordinator()
    
    var addVoiceShortcutViewController: INUIAddVoiceShortcutViewController?
    
    func show(for shortcut: INShortcut, with presenter: UIViewController) {
        let addVoiceShortcutViewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        addVoiceShortcutViewController.delegate = self
        presenter.present(addVoiceShortcutViewController, animated: true)
        self.addVoiceShortcutViewController = addVoiceShortcutViewController
    }

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
        addVoiceShortcutViewController = nil
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
        addVoiceShortcutViewController = nil
    }
    
}

#endif
