//
//  ActivityEligibility.swift
//  FlintCore
//
//  Created by Marc Palmer on 20/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The type for determining what kind of `NSUserActivity` eligibility should be expose when publishing
/// activities.
public enum ActivityEligibility {
    /// Specify `perform` only if you do not have other specific eligibility options included and you
    /// want standard `NSUserActivity` behaviour which can lead do Siri pro-active/suggestions only.
    case perform
    
    /// Specify this eligibility to support handoff for the action
    case handoff
    
    /// Specify this to also register for Spotlight search when the activity is published.
    /// - note: Normally you will index items for spotlight using Spotlight APIs.
    case search
    
    /// Specify this if the activity refers to publicly accessible content that should be indexed.
    /// - note: This requires a public web URL is set on the activity
    case publicIndexing
    
    /// Allow the activity to qualify for Siri prediction
    case prediction
}
