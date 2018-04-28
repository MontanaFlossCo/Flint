//
//  ObserverSet.swift
//  FlintCore
//
//  Created by Marc Palmer on 07/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A set of observers that can be called on specific queues.
class ObserverSet<T: AnyObject> {
    private struct ObserverQueuePair {
        weak var observer: T?
        let queue: SmartDispatchQueue
    }

    private var observers = [ObserverQueuePair]()
    
    /// Add an observer that will be called on the specified queue
    func add(_ observer: T, using queue: SmartDispatchQueue) {
        observers.append(ObserverQueuePair(observer: observer, queue: queue))
    }
    
    /// Remove an observer
    func remove(_ observer: T) {
        observers = Array(observers.filter( { (pair: ObserverQueuePair) -> Bool in
            pair.observer !== observer
        }))
    }

    /// Notify all the observers on their respective queues, asynchronously
    func notifyAsync(handler: @escaping (T) -> Void) {
        observers.forEach { pair in
            if let observer = pair.observer {
                pair.queue.syncOrAsyncIfDifferentQueue {
                    handler(observer)
                }
            }
        }
    }

    /// Notify all the observers on their respective queues, synchronously
    func notifySync(handler: @escaping (T) -> Void) {
        observers.forEach { pair in
            if let observer = pair.observer {
                pair.queue.sync {
                    handler(observer)
                }
            }
        }
    }
}
