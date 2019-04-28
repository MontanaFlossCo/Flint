//
//  TopicPath.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 16/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// An abstract "path" for log events.
///
/// This is used to provide a simple hierarchical structure to log events to facilitate filtering and collapsing,
/// mostly by Features but also arbitrary paths for non-Feature based subsystems.
public struct TopicPath: Hashable, CustomStringConvertible, ExpressibleByArrayLiteral {
    
    public let path: [String]
    public let description: String

#if swift(<4.2)
    public var hashValue: Int {
        return _hashValue
    }
#else
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_hashValue)
    }
#endif
    private let _hashValue: Int
    
    /// Initialise the path with an array of strings, e.g. `["UI", "Search"]` or `["Network", "JSON Cache"]`
    public init(_ path: [String]) {
        self.path = path
        _hashValue = path.joined().hashValue
        description = path.joined(separator: "/")
    }
    
    /// A convenience initialiser to permit assigning topic paths from array literals e.g.:
    /// `let topicToFocus: TopicPath = ["UI", "Search"]`
    public init(arrayLiteral elements: String...) {
        self.init(elements)
    }

    /// - return: A new topic path with the specified string appended to the end of the path as a new node
    public func appending(_ topic: String) -> TopicPath {
        var result = path
        result.append(topic)
        return TopicPath(result)
    }

    /// - return: `true` if `other` is prefixed with the same path elements as this topic path
    public func matches(_ other: TopicPath) -> Bool {
        guard path.count <= other.path.count else {
            return false
        }
        return other.path.prefix(upTo: path.count).elementsEqual(path)
    }
    
    /// - return: A new topic path pointing to the immediate parent of this path, or nil if this path has only
    /// one node.
    public func parentPath() -> TopicPath? {
        let result = path.dropLast()
        if result.count == 0 {
            return nil
        } else {
            return TopicPath(Array(result))
        }
    }
    
    // MARK: Equatable
    
    public static func ==(lhs: TopicPath, rhs: TopicPath) -> Bool {
        return lhs.path == rhs.path
    }
}
