//
//  PagedResultsController.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/03/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

@objc public protocol TimeOrderedResultsControllerDataSourceObserver {
    /// Results are provided sorted in the natural time order of the data source
    func dataSourceNewResultsInserted(items: [Any])
    func dataSourceOldResultsLoaded(items: [Any])
}

public protocol TimeOrderedResultsControllerDataSource: AnyObject {
    func add(observer: TimeOrderedResultsControllerDataSourceObserver, using queue: DispatchQueue)
    func remove(observer: TimeOrderedResultsControllerDataSourceObserver)
    func loadItems(after item: Any?, maxCount: Int)
}

/// !!! TODO: Remove @objc and change entry to `struct` when Swift bug SR-6039 is fixed.
/// - see: https://bugs.swift.org/browse/SR-6039
@objc public protocol TimeOrderedResultsControllerDelegate: AnyObject {
    /// Results are provided sorted in the natural time order of the data source
    func newResultsInserted(items: [Any])

    /// Results are provided sorted in the natural time order of the data source
    func oldResultsLoaded(items: [Any])
}

/// A controller for managing results from a data source that inserts new items over time,
/// and can load pages of older items.
///
/// This will call into its delegate to indicate when new items are inserted or old items have been loaded.
///
/// - note: Does not support random access. We don't need it.
public class TimeOrderedResultsController: TimeOrderedResultsControllerDataSourceObserver {
    public private(set) weak var delegate: TimeOrderedResultsControllerDelegate?
    public private(set) var dataSource: TimeOrderedResultsControllerDataSource
    private var oldestSeenItem: Any?
    private var allItems: [Any] = []
    private let delegateQueue: DispatchQueue
    private let delegateQueueKey: DispatchSpecificKey<ObjectIdentifier>

    public init(dataSource: TimeOrderedResultsControllerDataSource, delegate: TimeOrderedResultsControllerDelegate, delegateQueue queue: DispatchQueue) {
        self.delegate = delegate
        self.dataSource = dataSource
        delegateQueue = queue
        delegateQueueKey = DispatchSpecificKey<ObjectIdentifier>()
        queue.setSpecific(key: delegateQueueKey, value: ObjectIdentifier(self))
        dataSource.add(observer: self, using: queue)
    }
    
    /// Load more items at the end of the results. The delegate will be notified via dataSourceOldResultsLoaded
    /// - note: May call the delegate synchronously on the current queue.
    public func loadMore(count: Int) {
        dataSource.loadItems(after: oldestSeenItem, maxCount: count)
    }

    public func dataSourceNewResultsInserted(items: [Any]) {
        let notify = { [weak self] in
            self?.allItems.insert(contentsOf: items, at: 0)
            self?.delegate?.newResultsInserted(items: items)
        }
        
        if ObjectIdentifier(self) == DispatchQueue.getSpecific(key: delegateQueueKey) {
            notify()
        } else {
            delegateQueue.async(execute: notify)
        }
    }
    
    public func dataSourceOldResultsLoaded(items: [Any]) {
        let notify = { [weak self] in
            // Results come in newest-first, so if we load more later we load "since the last one"
            if let last = items.last {
                self?.oldestSeenItem = last
                
                self?.delegate?.oldResultsLoaded(items: items)
            }
        }
        if ObjectIdentifier(self) == DispatchQueue.getSpecific(key: delegateQueueKey) {
            notify()
        } else {
            delegateQueue.async(execute: notify)
        }
    }
}

