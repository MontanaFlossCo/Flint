//
//  URLPattern.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface to a URLPattern that can be matched to an incoming path and generate "reverse" paths
public protocol URLPattern {
    /// The URL pattern string to match
    var urlPattern: String { get }
    
    /// Indicates whether or not this pattern is capable of generating paths - some kinds of patterns
    /// have wildcard sections that cannot be populated when generating a path, so they are not useful for link generation
    var isValidForLinkCreation: Bool { get }
    
    /// Attempt to match the given URL path to this pattern, parsing out any parameters encoded in the path
    /// - return: The parameters extracted from the URL, or an empty dictionary if the match succeeded. `nil` if not.
    func match(path: String) -> [String:String]?
    
    /// Attempt to build a URL path using the given parameters
    func buildPath(with parameters: [String:String]?) -> String?
}

public class AnyURLPattern: URLPattern {
    public let urlPattern: String
    public let isValidForLinkCreation: Bool
    
    private let matchFunction: (_ path: String) -> [String:String]?
    private let buildPathFunction: (_ parameters: [String:String]?) -> String?

    init<PatternType>(pattern: PatternType) where PatternType: URLPattern {
        urlPattern = pattern.urlPattern
        isValidForLinkCreation = pattern.isValidForLinkCreation
        matchFunction = pattern.match(path:)
        buildPathFunction = pattern.buildPath(with:)
    }
    
    public func match(path: String) -> [String:String]? {
        return matchFunction(path)
    }
    
    /// Attempt to build a URL path using the given parameters
    public func buildPath(with parameters: [String:String]?) -> String? {
        return buildPathFunction(parameters)
    }

    public static func ==(lhs: AnyURLPattern, rhs: AnyURLPattern) -> Bool {
        return lhs.urlPattern == rhs.urlPattern &&
            lhs.isValidForLinkCreation == rhs.isValidForLinkCreation
    }
}
