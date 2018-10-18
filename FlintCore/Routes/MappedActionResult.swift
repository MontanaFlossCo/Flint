//
//  ActionRoutingResult.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Result type for functions that attempt to perform actions that are mapped either from URLs or activitys or Intents.
public enum MappedActionResult: Equatable {
    /// The mapping was resolved and the action performed, reporting success
    case success

    /// The mapping was resolved and the action is being performed asynchronously
    case completingAsync

    /// The mapping was resolved but the action failed
    case failure(error: Error?)
    
    /// The mapping failed, and did not resolve to an action
    case noMappingFound
    
    /// The Routes feature is disabled so the routing was not performed
    case featureDisabled
    
    public static func ==(lhs: MappedActionResult, rhs: MappedActionResult) -> Bool {
        switch (lhs, rhs) {
            case (.success, .success),
                 (.noMappingFound, .noMappingFound),
                 (.featureDisabled, .featureDisabled):
                return true
            case (.failure(let lhsError), .failure(let rhsError)):
                switch (lhsError, rhsError) {
                    case (.none, .none):
                        return true
                    default:
                        return false // Assume errors are not equal, they are not necessarily Equatable so...
                }
            default:
                return false
        }
    }
}

