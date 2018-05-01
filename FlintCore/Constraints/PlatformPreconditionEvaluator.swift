//
//  PlatformPreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public class PlatformPreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .platform(id, version) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to platform evaluator")
        }
        switch (id, version) {
            case (.iOS, .any):
#if os(iOS)
                return true
#else
                return false
#endif
            case (.iOS, .atLeast(let version)):
#if os(iOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
            case (.watchOS, .any):
#if os(watchOS)
                return true
#else
                return false
#endif
            case (.watchOS, .atLeast(let version)):
#if os(watchOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
            case (.tvOS, .any):
#if os(tvOS)
                return true
#else
                return false
#endif
            case (.tvOS, .atLeast(let version)):
#if os(tvOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
            case (.macOS, .any):
#if os(macOS)
                return true
#else
                return false
#endif
            case (.macOS, .atLeast(let version)):
#if os(macOS)
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
#else
                return false
#endif
        }
    }
}
