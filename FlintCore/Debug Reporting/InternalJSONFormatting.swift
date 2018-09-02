//
//  InternalJSONFormatting.swift
//  FlintCore
//
//  Created by Marc Palmer on 15/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

// This file contains simple extensions that provide external JSON representations of Flint's types that are
// included in reports.
// No Codable support yet, it is debatable whether it is any better for this use case.

extension ActionStack {
    var jsonRepresentation: [String:Any?] {
        return withEntries { _ in
            let jsonEntries: [[String:Any?]] = withEntries { entries in
                return entries.map { $0.jsonRepresentation }
            }
            return [
                "start": Formatters.jsonDate(from: startDate),
                "active_time": timeIntervalToLastEntry,
                "id": id,
                "parent_id": parent?.id,
                "feature": feature.name,
                "session": sessionName,
                "entries": jsonEntries
            ]
        }
    }
}

extension ActionStackEntry {
    var jsonRepresentation: [String:Any?] {
        var results: [String:Any?] = [
            "start_date": Formatters.jsonDate(from: startDate),
            "user_initiated": userInitiated,
            "feature": feature.name,
            "session": sessionName
        ]
        switch details {
            case .substack(let stack):
                results["substack"] = stack.jsonRepresentation
            case .action(let name, let source, let input):
                var json: [String:Any?] = ["name": name, "source": String(describing: source)]
                if let input = input {
                    json["input"] = input
                }
                results["action"] = json
        }
        return results
    }
}

extension TimelineEntry {
    var jsonRepresentation: [String:Any?] {
        return [
            "id": uniqueID,
            "date": Formatters.jsonDate(from: date),
            "kind": kind == .begin ? "begin" : "complete",
            "user_initiated": userInitiated,
            "session": sessionName,
            "feature": feature.identifier.description,
            "action": actionName,
            "input": inputInfo
        ]
    }
}
