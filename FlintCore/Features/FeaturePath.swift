//
//  FeaturePath.swift
//  FlintCore
//
//  Created by Marc Palmer on 08/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A representation of a Feature's identity in the graph of features defined in the app.
///
/// This type is currently an alias to TopicPath
public typealias FeaturePath = TopicPath

extension FeaturePath  {
    func appending(feature: FeatureDefinition.Type) -> FeaturePath {
        return appending(String(describing: feature))
    }
}
