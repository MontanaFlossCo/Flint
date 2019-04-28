//
//  FocusArea.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Represents a topic path that you want to focus on for debugging.
///
/// This is an immutable wrapper used to allow the Focus feature to be used with either TopicPath or Feature.
///
/// - see: `FocusFeature`
public struct FocusArea: FlintLoggable, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
    public let topicPath: TopicPath
    
    public init(topicPath: TopicPath) {
        self.topicPath = topicPath
    }
    
    public init(feature: FeatureDefinition.Type) {
        self.topicPath = TopicPath(feature.identifier.path)
    }
    
    public var description: String {
        return topicPath.description
    }
    
    public var debugDescription: String {
        return "FocusArea on \(String(reflecting: topicPath))"
    }
    
#if swift(<4.2)
    public var hashValue: Int {
        return topicPath.hashValue
    }
#else
    public func hash(into hasher: inout Hasher) {
        hasher.combine(topicPath.hashValue)
    }
#endif

    public static func ==(lhs: FocusArea, rhs: FocusArea) -> Bool {
        return lhs.topicPath == rhs.topicPath
    }
}
