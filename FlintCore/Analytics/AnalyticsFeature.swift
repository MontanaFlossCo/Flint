//
//  AnalyticsFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The Analytics Feature sends analytics events for qualifying actions to your analytics provider.
final public class AnalyticsFeature: ConditionalFeature {
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }

    /// Set this to `false` at runtime to disable Timeline
    public static var isEnabled: Bool? = true
    
    public static var description: String = "Sends analytic events for qualifying actions to your analytics provider"

    public static var provider: AnalyticsProvider?
    
    public static func prepare(actions: FeatureActionsBuilder) {
        if isAvailable == true {
            let analyticsProvider = self.provider ?? ConsoleAnalyticsProvider()
            Flint.dispatcher.add(observer: AnalyticsReporting(provider: analyticsProvider))
        }
    }
}
