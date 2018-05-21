//
//  RegexURLPattern.swift
//  FlintCore
//
//  Created by Marc Palmer on 17/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public enum URLPatternResult {
    case noMatch
    case match(params: [String:String])
}

public protocol URLPattern /*: Hashable */ {
    func match(path: String) -> URLPatternResult
    func buildPath(with parameters: [String:String]?) -> String
}

///
/// A URL Pattern matcher that uses Grails-style matching to extract named parameter values from the path
/// and use them like query parameters. The following syntax is supported, _per path component_, so that
/// macros are not able to span components (i.e. path components cannot contain or match `/`):
///
/// * `$(paramName)` — e.g. `something$(param1)`, `$(param1)something`, `something$(param1)something`. The text where
/// `param1` is in the path is extracted into the query parameters with the key `param1`
/// * `*` — a wildcard that represents 1 or more "any" characters, e.g. `something*`, `*something`, `*`
/// * `**` — a wildcard that matches everything after it in the URL path. It is not valid to have `**` anywhere
/// except the final path component
///
/// ```
/// /store/categories/grindcore --> RequestParameters()
/// /store/$category/grindcore --> RequestParameters(["category":x])
/// /store/$category/items/$sku --> RequestParameters(["category":x, "sku": y])
/// /store/$category/items/** --> RequestParameters(["category":x], pathInfo: suffix) (** matches any suffix)
/// /store/$category/*/whatever --> RequestParameters(["category":x]) (* matches any component, not captured)
/// /store/$category/*/whatever?var1=a --> RequestParameters(["category":x, "var1":"a"])
/// /store/*/whatever?var1=a --> RequestParameters(["var1":"a"])
/// /store/*/**?var1=a --> RequestParameters(["var1":"a"], pathInfo: suffix)
/// /** --> RequestParameters([:], pathInfo: suffix)
/// ```
public class RegexURLPattern: URLPattern {
    public let urlPattern: String
    let namedComponents: [String]
    let regexPattern: NSRegularExpression
    let formatPattern: String?

    init(urlPattern: String) {
        self.urlPattern = urlPattern
        
        let components = urlPattern.split(separator: "/", maxSplits: Int.max, omittingEmptySubsequences: false).map { String($0) }
        print("components \(components)")
        var regexPatternString = ""
        var formatPatternString: String? = ""
        var namedComponents: [String] = []
        
        // match any non-whitespace, optionally in parens
        let namedVarExpression = try! NSRegularExpression(pattern: "\\$\\((\\S+?)\\)", options: [])
        print("namedVarExpre \(namedVarExpression)")
        /// !!! TODO: Escape \ and other regex special chars first
        for (componentIndex, component) in components.enumerated() {
            print("component: \(component)")
            if component.contains("$") {
                // match $xxxx, aaa$xxxx or aaa$(xxxx)bbbb, or aaa$(xxxx)bbb$(yyyy), replacing with regex aaa(.+)bbbb etc.
                let matches = namedVarExpression.matches(in: component, options: [], range: NSRange(location: 0, length: component.utf16.count))
                print("matches: \(matches)")
                if matches.count > 0 {
                    for match in matches {
                        print("match has ranges: \(match.numberOfRanges)")
                        // Hmm, is this utf16?
                        guard let range = Range(match.range(at: 1), in: component) else {
                            preconditionFailure("Could not convert NSRange \(match.range) to Range")
                        }
                        let name = component.utf16[range]
                        print("Matched var: \(String(name))")
                        namedComponents.append(String(name)!)
                    }
                    
                    // Replace all varname macros with a regex capture group
                    let regexConvertedComponent = namedVarExpression.stringByReplacingMatches(
                        in: component,
                        options: [],
                        range: NSRange(location: 0, length: component.utf16.count),
                        withTemplate: "(.+)")
                    regexPatternString.append("/")
                    regexPatternString.append(regexConvertedComponent)
                } else {
                    regexPatternString.append("/")
                    regexPatternString.append(component)
                }
                // Keep it as-is for re-linking later
                formatPatternString!.append("/\(component)")
            } else if component.contains("**") {
                precondition(componentIndex == components.count-1, "The recursive ** wildcard cannot be used here, it is only valid as the last path component. Pattern is: \(urlPattern)")
                // match ** for "all path suffix"
                regexPatternString.append("/.*")

                // Skip all the rest, nothing else applies. Log a warning?
                break
            } else if component.contains("*") {
                // We can't rebuild a link for these, we don't know what to put for the *
                formatPatternString = nil
                
                // match * for "one or more any chars"
                regexPatternString.append("/.+")
            } else {
                if !component.isEmpty || componentIndex > 0 {
                    regexPatternString.append("/")
                }
                regexPatternString.append(component)
            }
        }
        
        self.namedComponents = namedComponents
        let regexString = "^\(regexPatternString)$"
        print("regex: \(regexString)")
        self.regexPattern = try! NSRegularExpression(pattern: regexString, options: [])
        self.formatPattern = formatPatternString
    }
    
    public func match(path: String) -> URLPatternResult {
        let matches = regexPattern.matches(in: path, options: [], range: NSRange(location: 0, length: path.utf16.count))
        if matches.count > 0 {
            var params: [String:String] = [:]
            precondition(matches.count == 1, "URL pattern matching error, number of URL pattern matches can only be 1")
            guard let match = matches.first else {
                preconditionFailure("URL pattern matching error, no match")
            }
            
            var nameIndex = 0
            // This is only true if there was at least one named variable to extract
            if match.numberOfRanges > 1 {
                for index in 1..<match.numberOfRanges {
                    print("URL range \(index): \(match.range(at: index))")
                    let matchRange = match.range(at: index)
                    guard let range = Range(matchRange, in: path) else {
                        preconditionFailure("Could not convert NSRange \(matchRange) to Range")
                    }
                    let matchedValue = path.utf16[range]
                    let matchedName = namedComponents[nameIndex]
                    params[matchedName] = String(matchedValue)
                    nameIndex = nameIndex + 1
                }
            }
            return .match(params: params)
        } else {
            return .noMatch
        }
    }
    
    public func buildPath(with parameters: [String:String]?) -> String {
        guard let formatPattern = formatPattern else {
            preconditionFailure("The format pattern contains a * wildcard, and we cannote create a link to this: \(urlPattern)")
        }
        var result = formatPattern
        for namedComponent in namedComponents {
            guard let replacementValue = parameters?[namedComponent] else {
                preconditionFailure("Cannot create link with pattern \(urlPattern) because there is no value for \(namedComponent) in parameters: \(parameters ?? [:])")
            }
            result = result.replacingOccurrences(of: "$(\(namedComponent))", with: replacementValue)
        }
        return result
    }

    // MARK: Hashable
    
    public var hashValue: Int {
        return urlPattern.hashValue
    }
    
    public static func ==(lhs: RegexURLPattern, rhs: RegexURLPattern) -> Bool {
        return lhs.urlPattern == rhs.urlPattern
    }
}
