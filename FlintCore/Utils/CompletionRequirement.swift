//
//  CompletionRequirement.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 17/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A type that handles completion callbacks with safety checks and semantics
/// that reduce the risks of callers forgetting to call the completion handler.
///
/// To use, define a typealias for this type, with T the type of the completion function's arguments.
/// Then make a function that requires completion pass in an instance of this type instead of the closure type, and make
/// the function expect a return value of the nested `Status` type:
///
/// ```
/// protocol MyCoordinator {
///   typealias DoSomethingCompletion = CompletionRequirement<Bool>
///
///   func doSomething(input: Any, completionRequirement: DoSomethingCompletion) -> DoSomethingCompletion.Status
/// }
/// ```
///
/// Now, when calling this function on the protocol, you construct the requirement and verify the result:
///
/// ```
/// let coordinator: MyCoordinator = ...
/// let completion = MyCoordinator.DoSomethingCompletion( { shouldCancel in
///    print("Cancel? \(shouldCancel)")
/// })
///
/// let status = coordinator.doSomething(input: x, completionRequirement: completion)
/// // Make sure one of the valid statuses was returned.
/// // If result did not return try for `isCompletingAsync`, the completion callback will have already been called by now.
/// precondition(completion.verify(status))
/// ```
///
/// When implemention such a function requiring completion, you return one of two statuses returned by either
/// the `CompletionRequirement.completed(_ arg: T)` or `CompletionRequirement.willCompleteAsync()`.
///
/// ```
/// func doSomething(input: Any, completionRequirement: DoSomethingCompletion) -> DoSomethingCompletion.Status {
///    return completionRequirement.completed(false)
/// }
///
/// // or for async completion
///
/// func doSomething(input: Any, completionRequirement: DoSomethingCompletion) -> DoSomethingCompletion.Status {
///     let result = completionRequirement.willCompleteAsync()
///     DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
///         result.completed(false)
///     }
///     return result
/// }
/// ```
public class CompletionRequirement<T> {
    public class Status {
        let _value: T?
        var value: T {
            get {
                guard let result = _value else {
                    flintBug("CompletionRequirement status value is nil")
                }
                return result
            }
        }
        
        init() {
            _value = nil
        }

        init(result: T) {
            _value = result
        }
        
        public var isCompletingAsync: Bool { return false }
    }

    // The type for a status indicating completion will occur later
    public class DeferredStatus: Status {
        public let completed: (T) -> Void

        init(completionHandler: @escaping (T) -> Void) {
            self.completed = completionHandler
            super.init()
        }

        override public var isCompletingAsync: Bool { return true }
    }

    private var completionHandler: ((T) -> Void)?
    private var deferredCompletionStatus: DeferredStatus?
    private var completedStatus: Status!

    init(completionHandler: @escaping (T) -> Void) {
        self.completionHandler = completionHandler
    }

    public func verify(_ status: Status) -> Bool {
        return status === completedStatus || status === deferredCompletionStatus
    }
    
    public func willCompleteAsync() -> DeferredStatus {
        guard let completion = completionHandler else {
            flintUsageError("willCompleteLater() can only be called once per completion")
        }
        
        // Set "async" execution
        let status = DeferredStatus(completionHandler: completion)
        deferredCompletionStatus = status
        
        // Prevent accidental multiple-invocation
        completionHandler = nil
        
        // Return a status to inform the caller
        return status
    }

    public func completedSync(_ result: T) -> Status {
        guard let completionHandler = completionHandler else {
            flintUsageError("Cannot call completed() if willCompleteAsync() has been called - you must call completed() on the status returned from that call")
        }
        completedStatus = Status(result: result)
        completionHandler(result)
        return completedStatus
    }
}

