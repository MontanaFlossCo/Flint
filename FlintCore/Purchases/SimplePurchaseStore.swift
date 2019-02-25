//
//  SimplePurchaseStore.swift
//  FlintCore
//
//  Created by Marc Palmer on 10/02/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(macOS)
/// A very simple store of purchased Product IDs, using file protection but no other encryption.
///
/// This would well edited easily, but it is provided as a simple default implementation.
class SimplePurchaseStore {
    typealias PurchaseStatus = StoreKitPurchaseTracker.PurchaseStatus
    
    static let fileName = ".purchases.json"
    private let url: URL

    init(appGroupIdentifier: String?) throws {
        // We store this list in the documents directory
        let baseURL = try FileHelpers.flintInternalFilesURL(appGroupIdentifier: appGroupIdentifier)
        url = baseURL.appendingPathComponent(SimplePurchaseStore.fileName)
    }
    
    func load() throws -> [PurchaseStatus] {
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch let error {
            FlintInternal.logger?.error("Couldn't read purchases file: \(error)")
            return []
        }

        let decoder = JSONDecoder.init()
        guard let purchases = try? decoder.decode([PurchaseStatus].self, from: jsonData) else {
            FlintInternal.logger?.error("Couldn't read purchases file correctly")
            return []
        }
        return purchases
    }

    func save(productStatuses: [PurchaseStatus]) throws {
        let jsonData = try JSONEncoder().encode(productStatuses)

        try jsonData.write(to: url, options: .atomicWrite)
#if os(iOS) || os(watchOS)
        let attributes = [
             FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
#endif
    }
    
}
#endif
