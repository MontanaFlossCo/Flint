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
/// To use Analytics reporting, create an instance of this at runtime and add it to the ActionDispatcher observers:
///
/// ```
/// let myAnalyticsProvider = ConsoleAnalyticsProvider()
/// Flint.dispatcher.add(observer: AnalyticsReporting(provider: myAnalyticsProvider))
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
        guard request.actionBinding.action.analyticsID != nil else {
            return
        }
        let context = request.actionBinding.action.analyticsAttributes(for: request)
        provider.analyticsEventWillBegin(feature: request.actionBinding.feature,
                                         action: request.actionBinding.action,
                                         context: context)
    }
    
    public func actionDidComplete<FeatureType, ActionType>(_ request: ActionRequest<FeatureType, ActionType>, outcome: ActionPerformOutcome) {
        guard request.actionBinding.action.analyticsID != nil else {
            return
        }
        let context = request.actionBinding.action.analyticsAttributes(for: request)
        provider.analyticsEventDidEnd(feature: request.actionBinding.feature,
                                      action: request.actionBinding.action,
                                      context: context,
                                      outcome: outcome)
    }

}
