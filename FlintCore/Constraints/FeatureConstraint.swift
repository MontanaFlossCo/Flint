//
//  FeatureConstraint.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// All feature constraint types must conform to this protocol.
///
/// This protocol lets us get at basic information about any kind of constraint enum.
public protocol FeatureConstraint: Hashable {
    /// Implementations must return a meaningful name for display in debug UIs
    var name: String { get }

    /// Implementations must return human-readabke information about the constraint's parameters for display in debug UIs
    var parametersDescription: String { get }
}
