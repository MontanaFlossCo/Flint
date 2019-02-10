//
//  ErrorFunctions.swift
//  FlintCore
//
//  Created by Marc Palmer on 16/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is important information for the developer.
/// !!! TODO: This should be disabled in production builds
public func flintInformation(_ message: String) {
    print("☝️ \(message)")
}

/// This is an warning that something needs to be addressed before shipping.
/// !!! TODO: This should be disabled in production builds
public func flintAdvisoryNotice(_ message: String, file: StaticString = #file, line: UInt32 = #line) {
    print("🚑 \(message). See \(file) line \(line)")
}

/// This is an warning that something is definitely broken and needs to be addressed. AKA Footgun prevention.
/// !!! TODO: This should be disabled in production builds
public func flintAdvisoryPrecondition(_ expression: @autoclosure () -> Bool, _ message: String, file: StaticString = #file, line: UInt32 = #line) {
    if !expression() {
        fatalError("🚑 \(message). See \(file) line \(line)")
    }
}

/// AKA You are holding it wrong
/// !!! TODO: This should be disabled in production builds
public func flintUsagePrecondition(_ expression: @autoclosure () -> Bool, _ message: String, file: StaticString = #file, line: UInt32 = #line) {
    if !expression() {
        fatalError("⚠️  \(message). See \(file) line \(line)")
    }
}

public func flintUsageError(_ message: String, file: StaticString = #file, line: UInt32 = #line) -> Never {
    fatalError("⚠️  \(message). See \(file) line \(line)")
}

/// This is an internal bug, AKA "This should never happen"
/// !!! TODO: This should be disabled in production builds
public func flintBugPrecondition(_ expression: @autoclosure () -> Bool, _ message: String, file: StaticString = #file, line: UInt32 = #line) {
    if !expression() {
        fatalError("💣  \(message). See \(file) line \(line)")
    }
}

/// This is an internal bug, AKA "This should never happen"
public func flintBug(_ message: String, file: StaticString = #file, line: UInt32 = #line) -> Never {
    fatalError("💣  \(message). See \(file) line \(line)")
}

public func flintNotImplemented(_ message: String, file: StaticString = #file, line: UInt32 = #line)  -> Never {
    fatalError("🚧 Not implemented: \(message). See \(file) line \(line)")
}

