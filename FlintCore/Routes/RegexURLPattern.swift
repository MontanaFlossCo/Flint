//
//  RegexURLPattern.swift
//  FlintCore
//
//  Created by Marc Palmer on 17/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

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
/// /store/categories/grindcore --> parameters [:]
/// /store/$(category)/grindcore --> parameters ["category":x]
/// /store/$(category)/items/$(sku) --> parameters ["category":x, "sku": y]
/// /store/$(category)/items/** --> parameters ["category":x] (** matches any suffix)
/// /store/$(category)/*/whatever --> parameters ["category":x] (* matches any component, not captured)
/// /store/$(category)/*/whatever?var1=a --> parameters ["category":x, "var1":"a"]
/// /store/*/whatever?var1=a --> parameters ["var1":"a"]
/// /store/*/**?var1=a --> parameters ["var1":"a"]
/// /** --> parameters [:]
/// ```
public class RegexURLPattern: URLPattern {
 
    public let urlPattern: String
 
    public var isValidForLinkCreation: Bool {
        return formatPattern != nil
    }

    static let regexReservedChars = CharacterSet(charactersIn: "*?+[(){}^$|\\.")
    static let regexBracketForPathChars = "[^/]"
    static let tempMacroPlaceholder = "__MACRO__"
    
    let namedComponents: [String]
    let regexPattern: NSRegularExpression
    let formatPattern: String?

    init(urlPattern: String) {
        precondition(!urlPattern.isEmpty, "URL patterns must not be empty")
        precondition(urlPattern.hasPrefix("/"), "URL patterns must start with /")

        self.urlPattern = urlPattern
        
        let components = urlPattern.split(separator: "/", maxSplits: Int.max, omittingEmptySubsequences: false).map { String($0) }
        var regexPatternString = ""
        var formatPatternString: String? = ""
        var namedComponents: [String] = []
        
        // match any non-whitespace, optionally in parens
        let namedVarExpression = try! NSRegularExpression(pattern: "\\$\\((\\S+?)\\)", options: [])
        for (componentIndex, component) in components.enumerated() {
            if component.contains("$") {
                // match $(xxxx), aa$(xxxx)bbbb, or aaa$(xxxx)bbb$(yyyy), replacing with regex aaa(.+)bbbb etc.
                let matches = namedVarExpression.matches(in: component, options: [], range: NSRange(location: 0, length: component.utf16.count))
                if matches.count > 0 {
                    for match in matches {
                        // Hmm, is this utf16?
                        guard let range = Range(match.range(at: 1), in: component) else {
                            preconditionFailure("Could not convert NSRange \(match.range) to Range")
                        }
                        let name = component.utf16[range]
                        namedComponents.append(String(name)!)
                    }
                    
                    // This is a bit of a nasty hack, but it avoids us having to write a stateful parser at the moment.
                    
                    // 1. Replace all varname macros with constant string __MACRO__ that won't suffer from regex escaping
                    let macroSubstitutedComponent = namedVarExpression.stringByReplacingMatches(
                        in: component,
                        options: [],
                        range: NSRange(location: 0, length: component.utf16.count),
                        withTemplate: RegexURLPattern.tempMacroPlaceholder)

                    // 2. Escape what is left so we don't accidentally let through regex special chars in the literal parts
                    let regexEscapedComponent = RegexURLPattern.regexEscaped(macroSubstitutedComponent)

                    // 3. Replace all the constant __MACRO__ strings with regex capture groups
                    let regexSubstitutedComponent = regexEscapedComponent.replacingOccurrences(
                        of: RegexURLPattern.tempMacroPlaceholder,
                        with: "(\(RegexURLPattern.regexBracketForPathChars)+)")

                    // Now we have a string like `/1234\$\$\$456/prefix([^/])+suffix/whatever` we can append
                    regexPatternString.append("/")
                    regexPatternString.append(regexSubstitutedComponent)
                } else {
                    regexPatternString.append("/")
                    regexPatternString.append(component)
                }
                // Keep it as-is for re-linking later
                formatPatternString!.append("/\(component)")
            } else if component == "**" {
                precondition(componentIndex == components.count-1, "The recursive ** wildcard cannot be used here, it is only valid as the last path component. Pattern is: \(urlPattern)")

                // Match ** for "all the remaining path suffix"
                regexPatternString.append("/.*")

                // We expect the last component to be ** after a /, so we need to add the / back in to create links
                formatPatternString!.append("/")

                // Skip all the rest, nothing else applies. Log a warning?
                break
            } else if component.contains("*") {
                // We can't rebuild a link for these, we don't know what to put for the *
                formatPatternString = nil
                
                // Match * for "one or more any chars"
                regexPatternString.append("/\(RegexURLPattern.regexBracketForPathChars)+")
            } else {
                // Anything that makes it to here is a just standard literal component
                let regexEscapedComponent = RegexURLPattern.regexEscaped(component)

                if !regexEscapedComponent.isEmpty || componentIndex > 0 {
                    regexPatternString.append("/")
                    formatPatternString?.append("/")
                }

                regexPatternString.append(regexEscapedComponent)

                formatPatternString?.append(regexEscapedComponent)
            }
        }
        
        self.namedComponents = namedComponents

        // Anchor the regex
        let regexString = "^\(regexPatternString)$"
        self.regexPattern = try! NSRegularExpression(pattern: regexString, options: [])
        self.formatPattern = formatPatternString
    }
    
    public func match(path: String) -> [String:String]? {
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
            return params
        } else {
            return nil
        }
    }
    
    public func buildPath(with parameters: [String:String]?) -> String? {
        guard let formatPattern = formatPattern else {
            preconditionFailure("The format pattern contains a * wildcard, and we cannote create a link to this: \(urlPattern)")
        }
        var result: String = formatPattern
        for namedComponent in namedComponents {
            guard let replacementValue = parameters?[namedComponent] else {
                return nil
            }
            let substition: String = result.replacingOccurrences(of: "$(\(namedComponent))", with: replacementValue)
            result = substition.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        }
        return result
    }

    /// Escape regex reserved chars in the input, so that when creating regex strings from inputs
    /// we don't accidentally create invalid regexes if some of the input contains e.g. `$` or `\`
    static func regexEscaped(_ value: String) -> String {
        var result: String = ""
        for char in value.unicodeScalars {
            if regexReservedChars.contains(char) {
                result.append("\\")
            }
            result.append(String(char))
        }
        return result
    }
    
}
