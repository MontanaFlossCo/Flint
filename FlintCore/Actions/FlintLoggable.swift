//
//  FlintLoggable.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//
import Foundation

/// The protocol to which Inputs must conform to be logged usefully by Flint's logging, Timeline, Action Stacks etc.
///
/// Flint requires a human readable description of all inputs to use in logs and debug UI, as well as a structured
/// data representation for use in machine-readable outputs.
///
/// We cannot rely on `CustomStringConvertible` and `CustomDebugStringConvertible` for this as the developer may
/// not control the contents of these, and the semantics are not rigid enough for our use.
public protocol FlintLoggable {
    /// Must return a human-readable description the type for use in logs and debug UI
    var loggingDescription: String { get }
    
    /// Must return a machine-readable set of properties describing the type, for use in exported reports for
    /// later structure analysis or querying.
    /// !!! TODO: How should we handle this in terms of performance, memory and nesting?
    /// Just a flat chunk of data for now
    var loggingInfo: [String:String]? { get }
    
    static var isImmutableForLogging: Bool { get }
}

/// Add defaults that use `CustomStringConvertible` and `CustomDebugStringConvertible`, to ease adoption.
extension FlintLoggable {
    /// By default use `debugDescription` if it is supported, if not fall back to debug description.
    /// It is much better to provide a meaningful implementation on your own types
    public var loggingDescription: String {
        if let debugSelf = self as? CustomDebugStringConvertible {
            return debugSelf.debugDescription
        } else {
            return String(reflecting: self)
        }
    }
    
    public var loggingInfo: [String:String]? {
        return ["loggingDescription": loggingDescription]
    }

    public static var isImmutableForLogging: Bool {
        return true
    }
}

// Apply the default implementation to standard types from the runtime

extension URL: FlintLoggable {
    public var loggingInfo: [String:String]? {
        return ["url": absoluteString]
    }
}

extension Int: FlintLoggable {
    public var loggingInfo: [String:String]? {
        return ["value": description]
    }
}

extension UInt: FlintLoggable {
    public var loggingInfo: [String:String]? {
        return ["value": description]
    }
}

extension Float: FlintLoggable {
    public var loggingInfo: [String:String]? {
        return ["value": description]
    }
}

extension Double: FlintLoggable {
    public var loggingInfo: [String:String]? {
        return ["value": description]
    }
}

extension String: FlintLoggable {
    public var loggingDescription: String {
        return self
    }

    public var loggingInfo: [String:String]? {
        return ["value": description]
    }
}

// Apply proxying implementation to Optionals

extension Optional: FlintLoggable where Wrapped: FlintLoggable {
    public var loggingDescription: String {
        if case let .some(value) = self {
            return value.loggingDescription
        } else {
            return "nil"
        }
    }
    public var loggingInfo: [String:String]? {
        if case let .some(value) = self {
            return value.loggingInfo
        } else {
            return nil
        }
    }
}

