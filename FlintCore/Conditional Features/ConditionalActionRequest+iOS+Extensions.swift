//
//  ConditionalActionRequest+iOS+Extensions.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 09/11/2018.
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
extension ConditionalActionRequest {

    /// Call to invoke the system "Add Voice Shortcut" view controller for the given input to the conditionally-available
    /// action represented by this action request.
    ///
    /// - note: Currently only actions that support NSUserActivity by opting in with `activityEligibility` are supported.
    ///
    /// - param input: The input to pass to the action when it is later invoked from the Siri Shortcut by the user.
    /// - param presenter: The `UIViewController` to use to present the view controller
    @available(iOS 12, *)
    public func addVoiceShortcut(for input: ActionType.InputType, presenter: UIViewController) {
        guard let activity = ActionActivityMappings.createActivity(for: actionBinding, with: input, appLink: nil) else {
            flintUsageError("The action \(actionBinding.action) on feature \(actionBinding.feature) did not return an activity for the input \(input)")
        }
        let shortcut = INShortcut(userActivity: activity)
        AddVoiceShortcutCoordinator.shared.show(for: shortcut, with: presenter)
    }
}
#endif
