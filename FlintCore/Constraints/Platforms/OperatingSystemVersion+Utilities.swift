//
//  OperatingSystemVersion+Utilities.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Extension to make it easier to work with `OperatingSystemVersion`.
///
/// This makes it so you can initialize one with an Int e.g.
/// ```
/// let v: OperatingSystemVersion = 11
/// ```
extension OperatingSystemVersion: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(majorVersion: Int(value), minorVersion: 0, patchVersion: 0)
    }
}

/// Extension to add Hashable and Equatable to the system's version type.
/// - note: We need this for auto-synthesized Hashable & Equatable on enums + structs
extension OperatingSystemVersion: Hashable, Equatable {
    public static func ==(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return lhs.majorVersion == rhs.majorVersion &&
            lhs.minorVersion == rhs.minorVersion &&
            lhs.patchVersion == rhs.patchVersion
    }
    
#if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(majorVersion * minorVersion * patchVersion)
    }
#else
    public var hashValue: Int {
        return majorVersion * minorVersion * patchVersion
    }
#endif
}

