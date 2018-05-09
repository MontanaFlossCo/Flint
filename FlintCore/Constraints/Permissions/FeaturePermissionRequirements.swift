//
//  FeaturePermissionRequirements.swift
//  FlintCore
//
//  Created by Marc Palmer on 09/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A type that encapsulates information about the permission requirements of a feature, for
/// easy access when determining what to do in your app when a Feature is not available.
///
/// Use `notDetermined.count > 0` to detect when there are permissions that can be authorised.
public struct FeaturePermissionRequirements {
    /// The set of all permissions the feature requires, regardless of their current status
    public let all: Set<SystemPermission>

    /// The set of all as-yet-not-authorised-or-denied permissions the feature requires.
    /// This will *not* include permissions that are unsupported, denied or restricted
    public let notDetermined: Set<SystemPermission>

    /// The set of all denied permissions that the feature requires.
    /// This will only include permissions that the user has been offered to authorise and they
    /// denied access.
    public let denied: Set<SystemPermission>

    /// The set of all restricted permissions that the feature requires.
    /// This will only include permissions that the user is not able to access because of parental control or
    /// device profile restrictions
    public let restricted: Set<SystemPermission>
}
