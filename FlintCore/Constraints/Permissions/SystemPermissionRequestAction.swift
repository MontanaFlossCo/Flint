//
//  SystemPermissionRequestAction.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The type used to describe what to do with the current permission request during
/// an authorisation controller flow. Your `PermissionAuthorisationCoordinator` passes these values
/// to the completion handler of `willRequestPermission(:completion:)` to indicate what the controller
/// should do next.
///
/// - see: `PermissionAuthorisationCoordinator`
public enum SystemPermissionRequestAction {
    /// Continue and show the system permission request alert
    case request
    
    /// Skip this permission - perhaps because the user tapped "Not now" in your custom onboarding UI
    case skip
    
    /// Cancel the entire authorisation flow. `didCompletePermissionAuthorisation` will be called ont he coordinator.
    case cancelAll
}
