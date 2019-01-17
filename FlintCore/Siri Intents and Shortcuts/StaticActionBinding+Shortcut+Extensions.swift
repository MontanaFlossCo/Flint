//
//  StaticActionBinding+iOS+Extensions.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 25/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

// Workaround for inability to compile against just iOS 12+, using the new "Network" framework as an indicator
#if canImport(Network) && os(iOS)
extension StaticActionBinding {

    /// Call to invoke the system "Add Voice Shortcut" view controller for the given input to the action represented.
    /// by this action binding.
    ///
    /// - note: Currently only actions that support NSUserActivity by opting in with `activityEligibility` are supported.
    ///
    /// - param input: The input to pass to the action when it is later invoked from the Siri Shortcut by the user.
    /// - param presenter: The `UIViewController` to use to present the view controller
    @available(iOS 12, *)
    public func addVoiceShortcut(for input: ActionType.InputType, presenter: UIViewController) {
        VoiceShortcuts.addVoiceShortcut(action: ActionType.self, feature: FeatureType.self, for: input, presenter: presenter)
    }
}
#endif
