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
public class SmartDispatchQueue {
    public let queue: DispatchQueue
    public let queueKey: DispatchSpecificKey<ObjectIdentifier>
    private let ownerIdentifier: ObjectIdentifier
    
    /// Initialise with the given queue and an object that is classed as the "owner" of this smart queue.
    /// The "owner" is used to create a unique key when storing information in the queue.
    public init(queue: DispatchQueue, owner: AnyObject) {
        queueKey = DispatchSpecificKey()
        self.queue = queue
        self.ownerIdentifier = ObjectIdentifier(owner)
        let currentOwner = DispatchQueue.getSpecific(key: queueKey)
        // Don't set owner if the queue already has an owner
        if currentOwner == nil {
            queue.setSpecific(key: queueKey, value: ownerIdentifier)
        }
    }

    /// - return: `true` if called on the same queue as this smart queue was initialised
    public var isCurrentQueue: Bool {
        return ownerIdentifier == DispatchQueue.getSpecific(key: queueKey)
    }
    
    /// Perform a block synchronously, without crashing if called on the same queue as this smart queue
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
}
