//
//  ActivityType.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This type indicates what caused the continuation of an `NSUserActivity` in the app.
/// This is passed in the `source` of an Action's `context` so the receiver can tell
/// under what conditions it was invoked if performed as a result of a continuation.
public enum ActivityType {
    /// The activity came from a Spotlight search result being selected
    case search

    /// The activity came from a web browser
    case browsingWeb
    
    /// The activity came from ClassKit
    case classKit
    
    /// The activity is from a Siri Intent
    case siri

    /// The activity is assumed to come from Siri (suggestions/pro-active) or similar if no other indication is
    /// found in the activity
    case other

}
