//
//  MockPresenter.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

class MockPresenter {
    var called = false
    
    func actionWorkWasDone() {
        called = true
    }
}


class MockReturnValuePresenter<T> {
    var called = false
    var result: T?
    
    func actionWorkWasDone(_ value: T?) {
        called = true
        result = value
    }
}

