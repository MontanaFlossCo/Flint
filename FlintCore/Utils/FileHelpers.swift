//
//  FileHelpers.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Static helpers for file manipulation
enum FileHelpers {
    
    /// Return the URL for storing internal Flint files that do not get purged from the device.
    static func flintInternalFilesURL(appGroupIdentifier: String?) throws -> URL {
        let baseURL = try containerURL(appGroupIdentifier: appGroupIdentifier, in: .documentDirectory)
        let dirURL = baseURL.appendingPathComponent(".flint")
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        return dirURL
    }
    
    /// Get the URL for a user directory within the specified app group container, or the app's default container
    /// if the group ID is nil.
    static func containerURL(appGroupIdentifier: String?, in searchPathDirectory: FileManager.SearchPathDirectory) throws -> URL {
        let containerURL: URL
        if let groupID = appGroupIdentifier {
            guard let appGroupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
                fatalError("Couldn't get app group container with ID \(groupID)")
            }
            containerURL = appGroupUrl
        } else {
            containerURL = try FileManager.default.url(for: searchPathDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
        return containerURL
    }
}
