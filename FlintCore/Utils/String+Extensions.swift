//
//  String+Extensions.swift
//  FlintCore
//
//  Created by Marc Palmer on 06/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// String extensions for making more human-friendly output.
public extension String {

    /// Helper function for tokenizing CamelCaseTypeNames to an array of tokens e.g. `["Camel", "Case", "Type", "Names"]`
    /// Includes basic support for acronyms e.g. SomethingSomethingUI -> "Something Something UI"
    func camelCaseToTokens() -> [String] {
        var tokens = [String]()
        var token = ""
        var previousWasCaps = false
        var inRunOfCaps = false
        unicodeScalars.forEach {
            if CharacterSet.uppercaseLetters.contains($0) {
                if !previousWasCaps && token.count > 0 {
                    tokens.append(token)
                }
                if previousWasCaps {
                    inRunOfCaps = true
                    token.unicodeScalars.append($0)
                } else {
                    token = "\($0)"
                    previousWasCaps = true
                }
            } else {
                // If we're just hit lowercase after an acronym, such as the first "e" in "HTTPRequest",
                // add start of the run up to the penultimate caps letter as one token, and start a new token
                // with the first capital
                if inRunOfCaps {
                    let scalars = token.unicodeScalars
                    let acronym = String(scalars[..<scalars.index(before: scalars.endIndex)])
                    tokens.append(acronym)
                    token = String(token.last!)
                }
                token.unicodeScalars.append($0)
                previousWasCaps = false
                inRunOfCaps = false
            }
        }
        if token.count > 0 {
            tokens.append(token)
        }
        return tokens
    }
    
    /// Take a string self like "Open Document" and lowercase and filter out whitespace chars, returning: "open-document"
    func lowerCasedID() -> String {
        let desymboled = self.replacingOccurrences(of: "\\s", with: "-", options: .regularExpression)
        return desymboled.lowercased()
    }
}
