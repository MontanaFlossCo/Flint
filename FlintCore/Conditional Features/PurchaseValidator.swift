//
//  PurchaseValidator.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Implement this protocol to verify whether a specific purchase has been paid for.
///
/// You may implement this against whatever receipt system you use, but typically this is StoreKit.
///
/// Flint will call this multiple times for each productID that is required in a `PurchaseRequirement`,
/// so implementations only need to respond to single product requests.
public protocol PurchaseValidator {

    /// Return whether or not the specified product ID has been paid for (or should be enabled) by the user.
    /// If the status is not yet known, the implementation can return `nil` to indicate this indeterminate status.
    func isPurchased(_ productID: String) -> Bool?
}
