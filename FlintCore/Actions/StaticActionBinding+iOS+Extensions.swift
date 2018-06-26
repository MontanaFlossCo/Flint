//
//  StaticActionBinding+iOS+Extensions.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 25/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if os(iOS)
#if canImport(IntentsUI)
import UIKit
import IntentsUI
#endif
#endif

// Workaround for inability to compile against just iOS 12+, using the new "Network" framework as an indicator
#if canImport(Network) && os(iOS)
extension StaticActionBinding {

    @available(iOS 12, *)
    public func addVoiceShortcut(for input: ActionType.InputType, presenter: UIViewController) {
        guard let activity = ActionActivityMappings.createActivity(for: self, with: input, appLink: nil) else {
            fatalError("No NSUserActivity was created for \(self)")
        }
        let shortcut = INShortcut(userActivity: activity)
        AddVoiceShortcutCoordinator.shared.show(for: shortcut, with: presenter)
    }
}

@available(iOS 12, *)
@objc private class AddVoiceShortcutCoordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
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
