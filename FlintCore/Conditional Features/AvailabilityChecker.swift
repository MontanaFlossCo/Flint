//
//  AvailabilityChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// You can customise the checking of purchased and user toggled conditional features by
/// implementing this protocol 
public protocol AvailabilityChecker {
    func isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool?
}

