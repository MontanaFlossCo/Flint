//
//  LIFOArrayQueueDataSource.swift
//  FlintCore
//
//  Created by Marc Palmer on 07/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A TimeOrderedResultsControllerDataSource that is backed by a last-in, first-out queue
/// which is threadsafe and calls observers when items loaded or added.
///
/// - note: You can append items, modify observers and read the queue (using `snapshot()`) from any queue.
public class LIFOArrayQueueDataSource<T>: TimeOrderedResultsControllerDataSource where T:UniquelyIdentifiable {
    private var accessQueue = DispatchQueue(label: "tools.flint.LIFOArrayQueueDataSource")
    var observers = ObserverSet<TimeOrderedResultsControllerDataSourceObserver>()
    var lifoQueue: LIFOArrayQueue<T>
    
    public init(maxCount: Int) {
        lifoQueue = LIFOArrayQueue<T>(maxCount: maxCount)
    }
    
    public func append(_ item: T) {
        accessQueue.sync {
            self.lifoQueue.append(item)
            observers.notifyAsync {
                $0.dataSourceNewResultsInserted(items: [item])
            }
        }
    }
    
    /// Return a threadsafe copy of the current items
    public func snapshot() -> Array<T> {
        return accessQueue.sync { return lifoQueue.items }
    }
    
    public func add(observer: TimeOrderedResultsControllerDataSourceObserver, using queue: DispatchQueue) {
        accessQueue.sync { observers.add(observer, using: SmartDispatchQueue(queue: queue)) }
    }
    
    public func remove(observer: TimeOrderedResultsControllerDataSourceObserver) {
        accessQueue.sync { observers.remove(observer) }
    }
    
    // Load entries prior to the reference entry immediately.
    // The observer will be called synchronously on the current thread/queue, so ensure you call this only from
    // the queue the observer expects.
    public func loadItems(after item: Any?, maxCount: Int) {
        let items = accessQueue.sync { self.lifoQueue }
        
        guard let entry = item as? T else {
            let startIndex = max(0, items.count.advanced(by: -Int(maxCount)))
            let items = Array(items[startIndex..<items.count])
            // First results where `item` is nil are delivered sync to prevent unnecessary UI animation
            observers.notifySync {
                $0.dataSourceOldResultsLoaded(items: items.reversed())
            }
            return
        }

        // Maybe hash the items so this is faster for large data sets, although it is only for debug UI so
        // this is not so important.
        let indexOfEntry = items.index { existing -> Bool in
            return existing.uniqueID == entry.uniqueID
        }
        guard let index = indexOfEntry, index > 0 else {
            return
        }
        let startIndex = max(0, index.advanced(by: -Int(maxCount)))
        if startIndex < index {
            let items = Array(items[startIndex..<index])
            observers.notifyAsync {
                $0.dataSourceOldResultsLoaded(items: items.reversed())
            }
        }
    }
}
