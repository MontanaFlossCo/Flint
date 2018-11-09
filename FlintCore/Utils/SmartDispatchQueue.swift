//
//  SmartDispatchQueue.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A dispatch queue that will call a sync block inline if it can tell we are already on that queue,
/// avoiding the problem of having to know if you are on that queue already before calling sync().
///
/// It also supports synchronous execution of the block if on the correct queue already, or flipping that to async
/// if we are not on this queue.
///
/// - note: This is not safe to use when using Dispatch Queues that use a `target` queue. The block will execute on
/// the target queue, and `getSpecific` will not return the correct value
public class SmartDispatchQueue: Equatable {
    public let queue: DispatchQueue
    private let queueKey: DispatchSpecificKey<KeyType>

    private struct KeyType { }
    
    /// Initialise with the given queue, with the ability to test if we are on this queue later.
    public init(queue: DispatchQueue) {
        queueKey = DispatchSpecificKey<KeyType>()
        self.queue = queue
        queue.setSpecific(key: queueKey, value: KeyType())
    }

    deinit {
        // Clear the value for the key, for what it's worth
        queue.setSpecific(key: queueKey, value: nil)
    }
    
    /// - return: `true` if called on the same queue as this smart queue was initialised
    public var isCurrentQueue: Bool {
        return DispatchQueue.getSpecific(key: queueKey) != nil
    }
    
    /// Perform a block synchronously, without crashing if called on the same queue as this smart queue
    @discardableResult
    public func sync<T>(execute block: () -> T) -> T {
        if isCurrentQueue {
            return block()
        } else {
            return queue.sync(execute: block)
        }
    }

    /// Perform a block synchronously, without crashing if called on the same queue as this smart queue,
    /// or fall back to asynchronous invocation on this queue.
    public func syncOrAsyncIfDifferentQueue(execute block: @escaping () -> Void) {
        if isCurrentQueue {
            block()
        } else {
            queue.async(execute: block)
        }
    }
    
    // MARK: Equatable
    
    public static func ==(lhs: SmartDispatchQueue, rhs: SmartDispatchQueue) -> Bool {
        return lhs.isCurrentQueue && rhs.isCurrentQueue
    }
}
