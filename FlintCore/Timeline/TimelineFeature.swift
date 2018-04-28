//
//  TimelineFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 26/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The Timeline Feature gathers information about the actions the app performs.
/// You can use this to reproduce the steps the user took to arrive at a certain point or crash.
///
/// Entries are stored in a LIFO queue restricted to a maximum number of entries to prevent using every-growing
/// amounts of memory.
///
/// - see: `Timeline.snapshot()` for access to the data gathers.
final public class TimelineFeature: ConditionalFeature {
    public static var availability: FeatureAvailability = .custom
    
    public static var description: String = "Maintains an in-memory timeline of actions for debugging and reporting"

    /// Set this to `false` at runtime to disable Timeline
    public static var isAvailable: Bool? = true
    
    public static func prepare(actions: FeatureActionsBuilder) {
        if isAvailable == true {
            // Tracks the user's history of actions performed
            Flint.dispatcher.add(observer: Timeline.instance)
        }
    }
}
