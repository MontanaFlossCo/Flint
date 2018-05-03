//
//  PlatformVersionConstraint.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum PlatformVersionConstraint: Hashable, Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
    case any
    case atLeast(version: OperatingSystemVersion)
    case unsupported

    public typealias IntegerLiteralType = UInt
    public typealias StringLiteralType = String
    
    public init(integerLiteral value: IntegerLiteralType) {
        self = .atLeast(version: OperatingSystemVersion(integerLiteral: value))
    }
    
    public init(stringLiteral value: StringLiteralType) {
        let parts = value.split(separator: ".")
        guard (1...3).contains(parts.count) else {
            fatalError("Platform versions specified as strings must have between one and three parts. This has \(parts.count): \(value)")
        }
        let numbers: [Int?] = parts.map { return Int($0) }
        guard numbers.first(where: { $0 == nil }) == nil else {
            fatalError("Platform versions specified as strings must have only integer parts: \(value)")
        }
        let major = numbers[0]!
        var minor = 0
        var patch = 0
        if numbers.count > 1 {
            minor = numbers[1]!
        }
        if numbers.count > 2 {
            patch = numbers[2]!
        }
        self = .atLeast(version: OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch))
    }

    public var isCurrentCompatible: Bool {
        switch self {
            case .any:
                return true
            case .atLeast(let version):
                return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
            case .unsupported:
                return false
        }
    }
    
    public var description: String {
        switch self {
            case .any: return "*"
            case .atLeast(let version): return ">= \(version)"
            case .unsupported: return "unsupported"
        }
    }
}

