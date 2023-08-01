//
//  ActionPerformOutcome.swift
//  FlintCore
//
//  Created by Marc Palmer on 23/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The type that indicates the outcome of performing an action.
///
/// Actions use this result type to indicate whether or not the current action stack should be closed, indicating the
/// end of a sequence of action usage for a given feature.
public enum ActionPerformOutcome: CustomStringConvertible {

    /// The action completed successfully, but does not indicate that the feature is now "done".
    /// Usually this will be the outcome you use but when the action clearly indicates the user is no longer using
    /// the feature, e.g. closing a document for a "Document Editing Feature", you use `successWithFeatureTermination`
    case success

    /// The action completed successfully, and indicates that the feature is now "done".
    /// Usually this will not be the outcome you use for success. Unless the action clearly indicates the user is no longer using
    /// the feature, e.g. closing a document for a "Document Editing Feature", you should use `success`
    case successWithFeatureTermination
    
    /// The action failed to complete, but does not indicate that the feature is now "done".
    /// Usually this will be the outcome you use but when the action clearly indicates the user is no longer using
    /// the feature, e.g. closing a document for a "Document Editing Feature", you use `failureWithFeatureTermination`
    case failure(error: Error)

    /// The action failed to complete, and indicates that the feature is now "done".
    /// Usually this will not be the outcome you use for an error. Unless the action clearly indicates the user is no longer using
    /// the feature, e.g. closing a document for a "Document Editing Feature", you should use `failure`
    case failureWithFeatureTermination(error: Error)

    /// Returns `true` if the value is any one of the possible success cases
    var isSuccess: Bool {
        switch self {
            case .success,
                 .successWithFeatureTermination:
                return true
            default:
                return false
        }
    }
    
    /// Returns an `ActionOutcome` value equivalent to the current value, minus the action stack internals.
    var simplifiedOutcome: ActionOutcome {
        switch self {
            case .success,
                 .successWithFeatureTermination:
                return .success
            case .failure(let error):
                return .failure(error: error)
            case .failureWithFeatureTermination(let error):
                return .failure(error: error)
        }
    }
    
    /// Human-readable description of the cases
    public var description: String {
        switch self {
            case .success:
                return "success (not closing action stack)"
            case .successWithFeatureTermination:
                return "success (not closing action stack)"
            case .failure(let error):
                return "failure (not closing action stack) with error: \(String(describing: error)))"
            case .failureWithFeatureTermination(let error):
                return "failure (closing action stack) with error: \(String(describing: error)))"
        }
    }
}
