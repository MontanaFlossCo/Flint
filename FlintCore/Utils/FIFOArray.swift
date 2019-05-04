//
//  FIFOArray.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A queue of items that allows appending new items and automatically culls old items to stay within
/// `maxCount` items.
struct FIFOArray<T>: Sequence {
    public private(set) var items: [T] = []
    
    var maxCount: Int
    var count: Int { return items.count }
    
    init(maxCount: Int) {
        self.maxCount = maxCount
    }
    
    mutating func append(_ value: T) {
        items.append(value)
        if items.count > maxCount {
            items.remove(at: 0)
        }
    }

    func index(where condition: (_ value: T) -> Bool) -> Int? {
        return items.index(where: condition)
    }
    
    subscript(index: Int) -> T {
        return items[index]
    }

    subscript(range: CountableRange<Int>) -> ArraySlice<T> {
        return items[range]
    }
}

extension FIFOArray {
    func makeIterator() -> Array<T>.Iterator {
        return items.makeIterator()
    }
}
