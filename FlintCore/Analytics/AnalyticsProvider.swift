//
//  AnalyticsProvider.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Conform to this protocol to wire up your chosen Analytics service to receive events
/// when `Action`(s) that have an `analyticsID` set are performed.
///
/// Your implementation will receive the feature and action information, and the analytics properties returned
/// by your `Action` implementations' `analyticsAttributes(for:)` function.
///
/// Read the `analyticsID` for the event from the `action` passeds to the functions.
/// - see: `ConsoleAnalyticsProvider` for a trivial example implementation.
public protocol AnalyticsProvider {

    /// Implement and override this for specific action types to marshal the appropriate analytics keys if required
    func analyticsEventWillBegin<T>(feature: FeatureDefinition.Type, action: T.Type, context: [String:Any?]?) where T: Action
    
    /// Implement and override this for specific action types to marshal the appropriate analytics keys if required
    func analyticsEventDidEnd<T>(feature: FeatureDefinition.Type, action: T.Type, context: [String:Any?]?, outcome: ActionPerformOutcome) where T: Action

}
