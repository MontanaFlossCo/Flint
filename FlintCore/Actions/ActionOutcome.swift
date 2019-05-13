//
//  ActionOutcome.swift
//  FlintCore
//
//  Created by Marc Palmer on 19/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The type that indicates the outcome of performing an action
public enum ActionOutcome: Equatable {
    case success
    case failure(error: Error)
    
    public static func ==(lhs: ActionOutcome, rhs: ActionOutcome) -> Bool {
        switch (lhs, rhs) {
            case (.success, .success): return true
            default:
                return false
        }
    }
}
