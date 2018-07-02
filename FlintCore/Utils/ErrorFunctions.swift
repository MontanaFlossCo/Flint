//
//  Advisor.swift
//  FlintCore
//
//  Created by Marc Palmer on 16/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is an warning that something needs to be addressed before shipping.
public func flintAdvisoryNotice(_ message: String) {
    FlintInternal.logger?.warning("🚑 \(message)")
}

/// This is an warning that something is definitely broken and needs to be addressed. AKA Footgun prevention.
public func flintAdvisoryPrecondition(_ expression: @autoclosure () -> Bool, _ message: String) {
    if !expression() {
        fatalError("🚑 \(message)")
    }
}

/// AKA You are holding it wrong
public func flintUsagePrecondition(_ expression: @autoclosure () -> Bool, _ message: String) {
    if !expression() {
        fatalError("⚠️  \(message)")
    }
}

public func flintUsageError(_ message: String) -> Never {
    fatalError("⚠️  \(message)")
}

/// This is an internal bug, AKA "This should never happen"
public func flintBugPrecondition(_ expression: @autoclosure () -> Bool, _ message: String) {
    if !expression() {
        fatalError("💣  \(message)")
    }
}

/// This is an internal bug, AKA "This should never happen"
public func flintBug(_ message: String) -> Never {
    fatalError("💣  \(message)")
}

public func flintNotImplemented(_ message: String)  -> Never {
    fatalError("🚧 Not implemented: \(message)")
}

