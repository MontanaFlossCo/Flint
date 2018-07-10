//
//  FlintLoggable.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//
import Foundation

// The protocol to which Inputs must conform to be logged usefully by Flint's logging, Timeline, Action Stacks etc.
public protocol FlintLoggable {
    /// Should return a human-readable description the type
    var loggingDescription: String { get }
    
    /// Should return a machine-readable set of properties describing the type, for use in exported reports for
    /// later structure analysis or querying.
    /// !!! TODO: How should we handle this in terms of performance, memory and nesting?
    /// Just a flat chunk of data for now
    var loggingInfo: [String:String]? { get }
}

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
}

// Apply the default implementation to standard types from the runtime

extension URL: FlintLoggable { }
extension Int: FlintLoggable { }
extension Double: FlintLoggable { }
