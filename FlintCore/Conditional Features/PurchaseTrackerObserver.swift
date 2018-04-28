//
//  PurchaseValidatorObserver.swift
//  FlintCore
//
//  Created by Marc Palmer on 28/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The protocol for observers of changes to product purchase status
/// - note: `@objc` only because of SR-55.
/// - see: `PurchaseValidator`
@objc public protocol PurchaseTrackerObserver {
    func purchaseStatusDidChange(productID: String, isPurchased: Bool)
}
