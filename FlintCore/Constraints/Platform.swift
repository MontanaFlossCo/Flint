//
//  Platform.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Enum defining all the platforms that are supported, and whether we are
/// currently executing on them.
public enum Platform: Hashable, Equatable {
    case iOS
    case watchOS
    case tvOS
    case macOS
    
    public static let all: [Platform] = [iOS, watchOS, tvOS, macOS]
    
    public static var current: Platform {
#if os(iOS)
        return .iOS
#elseif os(watchOS)
        return .watchOS
#elseif os(tvOS)
        return .tvOS
#elseif os(macOS)
        return .macOS
#endif
    }
    
    public var isCurrentPlatform: Bool {
        switch self {
            case .iOS:
#if os(iOS)
                return true
#else
                return false
#endif
            case .watchOS:
#if os(watchOS)
                return true
#else
                return false
#endif
            case .tvOS:
#if os(tvOS)
                return true
#else
                return false
#endif
            case .macOS:
#if os(macOS)
                return true
#else
                return false
#endif
        }
    }
}
