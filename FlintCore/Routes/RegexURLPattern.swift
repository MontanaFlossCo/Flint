//
//  RegexURLPattern.swift
//  FlintCore
//
//  Created by Marc Palmer on 17/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

enum URLPatternResult {
    case noMatch
    case match(params: [String:String])
}

protocol URLPattern: Hashable {
    func match(path: String) -> URLPatternResult
}

class RegexURLPattern: URLPattern {
    let urlPattern: String
    let namedComponents: [String]
    let regexPattern: NSRegularExpression

    init(urlPattern: String) {
        self.urlPattern = urlPattern
        
        let components = urlPattern.split(separator: "/", maxSplits: Int.max, omittingEmptySubsequences: false).map { String($0) }
        print("components \(components)")
        var regexPatternString = ""
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
            } else if component.contains("**") {
                // match ** for "all path suffix"
                regexPatternString.append("/.*")
                // Skip all the rest, nothing else applies. Log a warning?
                break
            } else if component.contains("*") {
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
    }
    
    func match(path: String) -> URLPatternResult {
        let matches = regexPattern.matches(in: path, options: [], range: NSRange(location: 0, length: url.utf16.count))
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
}
