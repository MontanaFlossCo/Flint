//
//  AnalyticsReporting.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This class observes action execution and passes the analytics data to your analytics subsystem for any Actions that
/// support analytics.
///
/// This allows internal or third party frameworks that use Flint to expose functionality that you also track with analytics,
/// without them directly linking to the analytics package.
///
/// To use Analytics reporting, you need to make sure AnalyticsFeature.isEnabled is set to true,
/// and you need to set an implementation of `AnalyticsProvider` to the `AnalyticsFeature.provider` property before Flint
/// `setup` is called. By default this includes just a default console analytics provider.
///
/// ```
/// AnalyticsFeature.provider = MyGoogleAnalyticsProvider()
/// ```
///
/// - see: `AnalyticsProvider` for the protocol to conform to, to wire up your actual analytics service such as Mixpanel,
/// Google Analytics or preferably, your own back end.
public class AnalyticsReporting: ActionDispatchObserver {
    let provider: AnalyticsProvider
    
    /// Initialise the reporting with your own analytics provider instance that actually logs the data.
    public init(provider: AnalyticsProvider) {
        self.provider = provider
    }
    
    public func actionWillBegin<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>) {
        guard ActionType.analyticsID != nil else {
            return
        }
        let context =  ActionType.analyticsAttributes(for: request)
        provider.analyticsEventWillBegin(feature: FeatureType.self,
                                         action: ActionType.self,
                                         context: context)
    }
    
    public func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) {
        guard ActionType.analyticsID != nil else {
            return
        }
        let context = ActionType.analyticsAttributes(for: request)
        provider.analyticsEventDidEnd(feature: FeatureType.self,
                                      action:  ActionType.self,
                                      context: context,
                                      outcome: outcome)
    }

}
