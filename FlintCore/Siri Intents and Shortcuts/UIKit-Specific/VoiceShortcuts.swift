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

@available(iOS 12, *)
public enum AddVoiceShortcutResult {
    case added(shortcut: INVoiceShortcut)
    case failed(error: Error?)
    case cancelled
}

@available(iOS 12, *)
public enum EditVoiceShortcutResult {
    case updated(shortcut: INVoiceShortcut)
    case deleted(identifier: UUID)
    case failed(error: Error?)
    case cancelled
}

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
    static func addVoiceShortcut<ActionType, FeatureType>(action: ActionType.Type,
                                                          feature: FeatureType.Type,
                                                          for input: ActionType.InputType,
                                                          presenter: UIViewController,
                                                          completion: @escaping (_ result: AddVoiceShortcutResult) -> Void) where ActionType: Action, FeatureType: FeatureDefinition {
        guard let activity = ActionActivityMappings.createActivity(for: action, of: feature, with: input, appLink: nil) else {
            flintUsageError("The action \(action) on feature \(feature) did not return an activity for the input \(input)")
        }
        let shortcut = INShortcut(userActivity: activity)
        AddVoiceShortcutCoordinator.shared.show(for: shortcut, with: presenter, completion: completion)
    }

    @available(iOS 12, *)
    static func addVoiceShortcut<ActionType, FeatureType>(action: ActionType.Type,
                                                          feature: FeatureType.Type,
                                                          for input: ActionType.InputType,
                                                          presenter: UIViewController,
                                                          completion: @escaping (_ result: AddVoiceShortcutResult) -> Void) where ActionType: IntentAction, FeatureType: FeatureDefinition {
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

        AddVoiceShortcutCoordinator.shared.show(for: shortcut, with: presenter, completion: completion)
    }

    @available(iOS 12, *)
    static func editVoiceShortcut(_ voiceShortcut: INVoiceShortcut,
                                  presenter: UIViewController,
                                  completion: @escaping (_ result: EditVoiceShortcutResult) -> Void) {
        EditVoiceShortcutCoordinator.shared.show(for: voiceShortcut, with: presenter, completion: completion)
    }
}

/// Internal type to handle delegation of the Add Voice Shortcut UI.
@available(iOS 12, *)
@objc internal class AddVoiceShortcutCoordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    static let shared = AddVoiceShortcutCoordinator()
    
    var addVoiceShortcutViewController: INUIAddVoiceShortcutViewController?
    var completion: ((_ result: AddVoiceShortcutResult) -> Void)?
    
    func show(for shortcut: INShortcut, with presenter: UIViewController, completion: @escaping (_ result: AddVoiceShortcutResult) -> Void) {
        let addVoiceShortcutViewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        addVoiceShortcutViewController.delegate = self
        self.completion = completion
        presenter.present(addVoiceShortcutViewController, animated: true)
        self.addVoiceShortcutViewController = addVoiceShortcutViewController
    }

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true) { [weak self] in
            guard let completion = self?.completion else {
                return
            }
            let result: AddVoiceShortcutResult
            if let error = error {
                result = .failed(error: error)
            } else if let shortcut = voiceShortcut {
                result = .added(shortcut: shortcut)
            } else {
                flintBug("Shortcut was updated but no shortcut was received")
            }
            completion(result)
            self?.completion = nil
        }
        addVoiceShortcutViewController = nil
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.presentingViewController?.dismiss(animated: true) { [weak self] in
            guard let completion = self?.completion else {
                return
            }
            completion(.cancelled)
            self?.completion = nil
        }
        addVoiceShortcutViewController = nil
    }
    
}

/// Internal type to handle delegation of the Edit Voice Shortcut UI.
@available(iOS 12, *)
@objc internal class EditVoiceShortcutCoordinator: NSObject, INUIEditVoiceShortcutViewControllerDelegate {
    static let shared = EditVoiceShortcutCoordinator()
    
    var editVoiceShortcutViewController: INUIEditVoiceShortcutViewController?
    var completion: ((_ result: EditVoiceShortcutResult) -> Void)?
    
    func show(for voiceShortcut: INVoiceShortcut, with presenter: UIViewController, completion: @escaping (_ result: EditVoiceShortcutResult) -> Void) {
        let editVoiceShortcutViewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
        editVoiceShortcutViewController.delegate = self
        self.completion = completion
        presenter.present(editVoiceShortcutViewController, animated: true)
        self.editVoiceShortcutViewController = editVoiceShortcutViewController
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.presentingViewController?.dismiss(animated: true)  { [weak self] in
            guard let completion = self?.completion else {
                return
            }
            completion(.deleted(identifier: deletedVoiceShortcutIdentifier))
            self?.completion = nil
        }
        editVoiceShortcutViewController = nil
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true) { [weak self] in
            guard let completion = self?.completion else {
                return
            }
            let result: EditVoiceShortcutResult
            if let error = error {
                result = .failed(error: error)
            } else if let shortcut = voiceShortcut {
                result = .updated(shortcut: shortcut)
            } else {
                flintBug("Shortcut was updated but no shortcut was received")
            }
            completion(result)
            self?.completion = nil
        }
        editVoiceShortcutViewController = nil
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.presentingViewController?.dismiss(animated: true)  { [weak self] in
            guard let completion = self?.completion else {
                return
            }
            completion(.cancelled)
            self?.completion = nil
        }
        editVoiceShortcutViewController = nil
    }
    
}

#endif
