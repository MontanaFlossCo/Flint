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

extension StaticActionBinding {

#if os(iOS)
    @available(iOS 12, *)
    public func addVoiceShortcut(for input: ActionType.InputType, presenter: UIViewController) {
        guard let activity = ActionActivityMappings.createActivity(for: self, with: input, appLink: nil) else {
            fatalError("No NSUserActivity was created for \(self)")
        }
        let shortcut = INShortcut(userActivity: activity)
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        presenter.present(viewController, animated: true)
    }
#endif

}

