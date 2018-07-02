//
//  ConsoleAnalyticsProvider.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A trivial `AnalyticsProvider` implementation that simply outputs analytics to the console for debugging.
///
/// You can use this in developer builds to ensure all your expected analytics analytics are being produced.
public class ConsoleAnalyticsProvider: AnalyticsProvider {
    
    /// Implement and override this for specific action types to marshal the appropriate analytics keys if required
    public func analyticsEventWillBegin<T>(feature: FeatureDefinition.Type, action: T.Type, context: [String:Any?]?) where T: Action {
        guard let id = action.analyticsID else {
            flintBug("Analytics events must include an ID")
        }
        print("📊 Begin event: \(id) with \(context ?? [:])")
    }
    
    /// - note: Surely we'll need to include some kind of result of the action here?
    public func analyticsEventDidEnd<T>(feature: FeatureDefinition.Type, action: T.Type, context: [String:Any?]?, outcome: ActionPerformOutcome) where T: Action {
        guard let id = action.analyticsID else {
            flintBug("Analytics events must include an ID")
        }
        print("📊 Completed event: \(id) with \(context ?? [:]), outcome: \(outcome)")
    }

}
