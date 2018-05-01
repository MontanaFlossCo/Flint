//
//  UserFeatureTogglesObserver.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The protocol for observers of changes to user feature toggles
/// - note: `@objc` only because of SR-55.
/// - see: `UserFeatureToggles`
@objc public protocol UserFeatureTogglesObserver {
    /// Called when the state of a user feature toggle explicitly changes
    func userFeatureTogglesDidChange()
}
