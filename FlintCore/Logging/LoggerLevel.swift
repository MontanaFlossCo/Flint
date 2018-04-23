//
//  LoggerLevel.swift
//  FlintCore
//
//  Created by Marc Palmer on 31/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The Flint logging system's levels.
public enum LoggerLevel: Int, CustomStringConvertible {
    /// None is a special case in Flint to allow for suppression of logging internally
    case none
    case error
    case warning
    case info
    case debug

    public var description: String {
        switch self {
            case .none: return "None"
            case .error: return "Error"
            case .warning: return "Warning"
            case .info: return "Info"
            case .debug: return "Debug"
        }
    }
}

func <(lhs: LoggerLevel, rhs: LoggerLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func >(lhs: LoggerLevel, rhs: LoggerLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

func <=(lhs: LoggerLevel, rhs: LoggerLevel) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}

func >=(lhs: LoggerLevel, rhs: LoggerLevel) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}
