//
//  UniquelyIdentifiable.swift
//  FlintCore
//
//  Created by Marc Palmer on 07/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Items conforming to this have an unchanging ID which can be used to locate them
/// again in lists.
public protocol UniquelyIdentifiable {
    var uniqueID: String { get }
}

