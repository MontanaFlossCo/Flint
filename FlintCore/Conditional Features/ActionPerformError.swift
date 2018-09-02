//
//  ActionPerformError.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 27/08/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Errors that can be returned or thrown by code that performs actions
public enum ActionPerformError: Error {
    case requiredFeatureNotAvailable(feature: ConditionalFeatureDefinition.Type)
}
