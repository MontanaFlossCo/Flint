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
/// To use, define a typealias for this type, with T the type of the completion function's argument (use a tuple if
/// your completion requires multiple arguments).
///
/// Then make your function that requires a completion handler take an instance of this type instead of the closure type, and make
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
/// Now, when calling this function on the protocol, you construct the requirement instance, pass it and verify the result:
///
/// ```
/// let coordinator: MyCoordinator = ...
/// let completion = MyCoordinator.DoSomethingCompletion( { (shouldCancel: Bool, completedAsync: Bool) in
///    print("Cancel? \(shouldCancel)")
/// })
///
/// The block takes one argument of type `T`, in this case a boolean, and a second `Bool` argument that indicates
/// if the completion block has been called asynchronously.
///
/// // Call the function that requires completion
/// let status = coordinator.doSomething(input: x, completionRequirement: completion)
///
/// // Make sure one of the valid statuses was returned.
/// // This safety test ensures that the completion from the correct completion requirement instance was returned.
/// precondition(completion.verify(status))
///
/// // If the result does not return true for `isCompletingAsync`, the completion callback will have already been called by now.
/// if !status.isCompletingAsync {
///     print("Completed synchronously: \(status.value)")
/// } else {
///     print("Completing asynchronously... see you later")
/// }
/// ```
///
/// When implementing such a function requiring a completion handler, you return one of two statuses returned by either
/// the `CompletionRequirement.completed(_ arg: T)` or `CompletionRequirement.willCompleteAsync()`.
/// The `CompletionRequirement` will take care of calling the completion block as appropriate.
///
/// ```
/// func doSomething(input: Any, completionRequirement: DoSomethingCompletion) -> DoSomethingCompletion.Status {
///     return completionRequirement.completedSync(false)
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
        fileprivate let _value: T?
        fileprivate var value: T {
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
        var owner: CompletionRequirement<T>?
        
        init(owner: CompletionRequirement<T>) {
            self.owner = owner
            super.init()
        }

        override public var isCompletingAsync: Bool {
            return true
        }
        
        public func completed(_ result: T) {
            guard let owner = owner else {
                return
            }
            owner.completionHandler(result, true)
        }
    }

    fileprivate var completionStatus: Status?
    var completionHandler: ((T, _ completedAsync: Bool) -> Void)!

    public init(completionHandler: @escaping (T, _ completedAsync: Bool) -> Void) {
        self.completionHandler = completionHandler
    }

    /// Internal initialiser for proxy subclass, which will set the completion after
    fileprivate init() {
    }

    /// Call to verify that the result belongs to this completion instance and there hasn't been a mistake
    public func verify(_ status: Status) -> Bool {
        return status === completionStatus
    }
    
    /// Call to indicate that completion will be called later, asynchronously by code that has a reference
    /// to the deferred status.
    public func willCompleteAsync() -> DeferredStatus {
        guard completionStatus == nil else {
            flintUsageError("Only one of completedSync() or willCompleteLater() can be called")
        }
        
        // Set "async" execution
        let status = DeferredStatus(owner: self)
        completionStatus = status
        
        // Return a status to inform the caller
        return status
    }

    /// Call to indicate that completion is to be called immediately, synchronously
    public func completedSync(_ result: T) -> Status {
        guard self.completionStatus == nil else {
            flintUsageError("Only one of completedSync() or willCompleteLater() can be called")
        }
        
        let completionStatus = Status(result: result)
        completionHandler(result, false)
        self.completionStatus = completionStatus
        return completionStatus
    }
}

/// A `ProxyCompletionRequirement` allows you to provide a completion requirement that adds some custom completion logic
/// to an existing completion instance, and then return a possibly modified result value to the original requirement.
///
/// Very much turtles all the way down, and a bit nasty in the nuance of the implementation.
public class ProxyCompletionRequirement<T>: CompletionRequirement<T> {
    var proxiedCompletion: CompletionRequirement<T>
    
    public init(proxying originalCompletion: CompletionRequirement<T>, proxyCompletionHandler: @escaping (T, _ completedAsync: Bool) -> T) {
        self.proxiedCompletion = originalCompletion
        
        // Wrap the original completion handler, calling it with the result of possibly mutating it by our proxy completion handler
        super.init()
        
        self.completionHandler = { [weak self] result, completedAsync in
            guard let strongSelf = self else {
                return
            }
            
            // Get the actual (perhaps modified) result we're going to pass to the proxied completion handler
            let proxyResult = proxyCompletionHandler(result, completedAsync)
    
            if completedAsync {
                guard let proxiedDeferredStatus = strongSelf.proxiedCompletion.completionStatus as? DeferredStatus else {
                    flintBug("Proxy completion was completed async, but original completion did not have `willCompleteAsync` called")
                }
                proxiedDeferredStatus.completed(proxyResult)
            } else {
                let _ = strongSelf.proxiedCompletion.completedSync(proxyResult)
            }
        }
    }

    /// The proxy must indicate that the original completion will complete async, but we return our
    /// own proxy async status object because we need to inject our own completion handling logic to possibly
    /// mutate the value.
    override public func willCompleteAsync() -> CompletionRequirement<T>.DeferredStatus {
        let _ = proxiedCompletion.willCompleteAsync()
        return super.willCompleteAsync()
    }
    
    /// The proxy calls its own `completedAsync` in order to execute the custom value modification logic,
    /// and that will in fact call the original completion's `completedSync`.
    override public func completedSync(_ result: T) -> CompletionRequirement<T>.Status {
        let result = super.completedSync(result)
        guard let proxiedStatus = proxiedCompletion.completionStatus, !proxiedStatus.isCompletingAsync else {
            flintBug("Sync completion on proxied completion requirement did not store the proxied status")
        }
        return result
    }
}
