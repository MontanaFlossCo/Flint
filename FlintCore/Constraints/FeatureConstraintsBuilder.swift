//
//  FeatureConstraintsBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The protocol for the builder used to evaluate the `constraints` convention function
/// of conditional features.
public protocol FeatureConstraintsBuilder: AnyObject {

    /// Called to desclare a new platform requirement
    func platform(_ requirement: PlatformConstraint)

    /// Called to required checks to `isEnabled` every time availability checking is performed
    func runtimeEnabled()

    /// Called add a purchase requirement to a feaature
    /// - param requirement: The purchase requirement you wish to apply to the feature
    func purchase(_ requirement: PurchaseRequirement)

    /// Called to allow user toggling of the feature
    /// - param defaultValue: The default value to return this constraint if there is no preference stored.
    func userToggled(defaultValue: Bool)

    /// Called to desclare a new permission requirement
    func permission(_ permission: SystemPermission)
}
