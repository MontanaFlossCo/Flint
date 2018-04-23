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
    /// The action completed successfully. Pass `true` for `closeActionStack` if this action should
    /// result in the current action stack being closed, so no more actions are added to it.
    /// Usually this will be `false` but pass `true` when the action clearly indicates the user is no longer using
    /// the feature, e.g. closing a document for a "Document Editing Feature"
    case success(closeActionStack: Bool)

    /// The action encountered an error. Pass `true` for `closeActionStack` if this action should
    /// result in the current action stack being closed, so no more actions are added to it.
    /// Usually this will be `false` but pass `true` when the action clearly indicates the user is no longer using
    /// the feature, e.g. closing a document for a "Document Editing Feature"
    case failure(error: Error?, closeActionStack: Bool)
    
    var simplifiedOutcome: ActionOutcome {
        switch self {
            case .success(_): return .success
            case .failure(let error, _): return .failure(error: error)
        }
    }
    
    public var description: String {
        switch self {
            case .success(let terminates): return "success (closeActionStack: \(terminates))"
            case .failure(let error, let terminates): return "failure (closeActionStack: \(terminates), error: \(String(describing: error)))"
        }
    }
}
