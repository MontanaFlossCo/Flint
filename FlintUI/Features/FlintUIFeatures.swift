//
//  FlintUIFeatures.swift
//  FlintUI-iOS
//
//  Created by Marc Palmer on 28/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

/// All the features provided by Flint UI
public class FlintUIFeatures: FeatureGroup {
    public static let description: String = "Flint debugging UI"
    
    public static var subfeatures: [FeatureDefinition.Type] = [
        TimelineDataAccessFeature.self,
        FocusLogDataAccessFeature.self,
        TimelineBrowserFeature.self,
        LogBrowserFeature.self,
        ActionStackBrowserFeature.self,
        FeatureBrowserFeature.self
    ]
}
