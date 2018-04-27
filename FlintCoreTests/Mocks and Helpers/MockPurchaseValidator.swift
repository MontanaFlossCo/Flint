//
//  MockPurchaseValidator.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

class MockPurchaseValidator: PurchaseValidator {
    var fakePurchases: [String:Bool] = [:]
    
    func confirmNotPurchased(_ product: Product) {
        fakePurchases[product.productID] = false
    }
    
    func makeFakePurchase(_ product: Product) {
        fakePurchases[product.productID] = true
    }
    
    func reset() {
        fakePurchases.removeAll()
    }
    
    func isPurchased(_ productID: String) -> Bool? {
        return fakePurchases[productID]
    }
}
