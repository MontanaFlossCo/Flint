//
//  SimplePurchaseStore.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A very simple store of purchased Product IDs.
class SimplePurchaseStore {
    static let fileName = ".purchases.json"
    private let url: URL

    init(appGroupIdentifier: String?) throws {
        // We store this list in the documents directory
        let baseURL = try FileHelpers.flintInternalFilesURL(appGroupIdentifier: appGroupIdentifier)
        url = baseURL.appendingPathComponent(SimplePurchaseStore.fileName)
    }
    
    func load() throws -> [String] {
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch let error {
            FlintInternal.logger?.error("Couldn't read purchases file: \(error)")
            return []
        }

        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let purchases = jsonObject as? [String] else {
            FlintInternal.logger?.error("Couldn't read purchases file correctly")
            return []
        }
        return purchases
    }

    func save(productIDs: [String]) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: productIDs, options: [])

        try jsonData.write(to: url, options: .atomicWrite)
#if os(iOS) || os(watchOS)
        let attributes = [
             FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
#endif
    }
    
}
