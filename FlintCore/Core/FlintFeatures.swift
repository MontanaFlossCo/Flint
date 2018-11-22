//
//  FlintFeatures.swift
//  FlintCore
//
//  Created by Marc Palmer on 17/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The set of features provided by Flint itself.
///
/// These are Used to scope and filter logging of Flint itself, and to allow you to disable features of Flint that
/// you do not wish to use.
public final class FlintFeatures: FeatureGroup {
    public static var description = "Features provided by the Flint framework"
    
    public static var subfeatures: [FeatureDefinition.Type] = [
        RoutesFeature.self,
        ActivitiesFeature.self,
        TimelineFeature.self,
        FocusFeature.self,
        SiriIntentsFeature.self
    ]
}
