//
//  URLRoutingResult.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Result type for functions that attempt to perform actions via URLs.
public enum URLRoutingResult: Equatable {
    /// The URL routing was resolved and the action performed, reporting success
    case success

    /// The URL routing was resolved and the action failed
    case failure(error: Error?)
    
    /// The URL routing failed, and did not resolve to a declared route
    case noMappingFound
    
    /// The Routes feature is disabled so the routing was not performed
    case featureDisabled
    
    public static func ==(lhs: URLRoutingResult, rhs: URLRoutingResult) -> Bool {
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

