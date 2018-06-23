//
//  Advisor.swift
//  FlintCore
//
//  Created by Marc Palmer on 16/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is an warning that something is definitely broken and needs to be addressed. AKA Footgun prevention.
func flintAdvisoryAssert(_ expression: @autoclosure () -> Bool, _ message: String) {
    if !expression() {
        fatalError("🚑 \(message)")
    }
}

/// AKA You are holding it wrong
func flintUsageAssert(_ expression: @autoclosure () -> Bool, _ message: String) {
    if !expression() {
        fatalError("⚠️  \(message)")
    }
}

/// This is an internal bug, AKA "This should never happen"
func flintBug(_ expression: @autoclosure () -> Bool, _ message: String) {
    if !expression() {
        fatalError("💣  \(message)")
    }
}

/// This is an internal bug, AKA "This should never happen"
func flintBug(_ message: String) {
    fatalError("💣  \(message)")
}

