//
//  FlintAppInfo.swift
//  FlintCore
//
//  Created by Marc Palmer on 07/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This class acts as a registry of information about your App, for Flint to use.
///
/// Primarily this is used for access to information about the custom URL schemes and universal link domains your app supports.
///
/// - note: Flint cannot currently extract your supported universal link domains as these are only stored in your
/// entitlements file. The custom URL schemes are listed in your `Info.plist` so for most cases Flint can extract these.
final public class FlintAppInfo {
    /// Return the list of App URL schemes supported, as shown in the App's Info.plist, merging in
    /// any specified in `testURLSchemes` used for unit testing.
    public static var urlSchemes: [String] = {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String:Any]] else {
            return []
        }
        let schemeLists: [[String]] = urlTypes.compactMap { dict in
            if let list = dict["CFBundleURLSchemes"] as? [String] {
                return list
            } else {
                return nil
            }
        }
        let schemes: [String] = schemeLists.flatMap { $0 }
        return testURLSchemes + schemes
    }()

    /// A list of runtime-supplied URL schemes used for unit testing only
    public static var testURLSchemes = [String]()

    /// The associatedDomains supported by the app. This must be populated by the app at runtime,
    /// as this information is not available from the entitlements file of a release app.
    public static var associatedDomains = [String]()
    
    /// The NSURLActivityTypes supported by the app, as declared in Info.plist
    public static var activityTypes: [String] = {
        let types = Bundle.main.infoDictionary?["NSUserActivityTypes"]
        guard let stringTypes = types as? [String] else {
            return []
        }
        return stringTypes
    }()
    
    /// The default App Group ID to use for shared storage.
    /// - note: By default logs and purchase tracking info may be stored in this container.
    /// Set this before initialising Flint.
    public static var appGroupIdentifier: String? = nil
}
