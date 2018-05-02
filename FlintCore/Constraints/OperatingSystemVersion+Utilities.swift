//
//  OperatingSystemVersion+Utilities.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

extension OperatingSystemVersion: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(majorVersion: Int(value), minorVersion: 0, patchVersion: 0)
    }
}

extension OperatingSystemVersion: Hashable, Equatable {
    public static func ==(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return lhs.majorVersion == rhs.majorVersion &&
            lhs.minorVersion == rhs.minorVersion &&
            lhs.patchVersion == rhs.patchVersion
    }
    
    public var hashValue: Int {
        return majorVersion * minorVersion * patchVersion
    }
}

