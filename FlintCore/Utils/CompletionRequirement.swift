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
/// // or for async completion, you retain the result and later call `completed(value)`
///
/// func doSomething(input: Any, completionRequirement: DoSomethingCompletion) -> DoSomethingCompletion.Status {
///     // Capture the async status
///     let result = completionRequirement.willCompleteAsync()
///     DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
///         // Use the retained status to indicate completion later
///         result.completed(false)
///     }
///     return result
/// }
/// ```
public class CompletionRequirement<T> {

    /// An "abstract" base for the status result type.
    /// By design it must not be possible to instantiate this type in apps, so we can trust
    /// the instance handed back to the app matches our semantics.
    public class Status {
        /// This initialiser *must not* be publicly accessible because it prevents maverick devs
        /// misunderstanding the API and instantiating a status themselves, defeating the completion mechanism.
        fileprivate init() {
        }

        public var isCompletingAsync: Bool {
            flintBug("This base must not be instantiated")
        }
    }

    /// The status that indicates completion occurred synchronously.
    public class SyncCompletionStatus: Status {
        override public var isCompletingAsync: Bool {
            return false
        }
    }

    /// The type for a status indicating completion will occur later.
    /// The caller must retain this and call `completed` at a later point.
    public class DeferredStatus: Status {
        var owner: CompletionRequirement<T>?
        
        /// This initialiser *must not* be publicly accessible because it prevents maverick devs
        /// misunderstanding the API and instantiating a status themselves, defeating the completion mechanism.
        fileprivate init(owner: CompletionRequirement<T>) {
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
            owner.callCompletion(result, callingAsync: true)
        }
    }

    /// The status of this completion. This can be set only once.
    fileprivate var completionStatus: Status? {
        willSet {
            flintBugPrecondition(completionStatus == nil, "Completion status is being set more than once")
        }
    }
    
    /// The completion handler to call.
    fileprivate var completionHandler: ((T, _ completedAsync: Bool) -> Void)?

    /// Instantiate a new completion requirement that calls the supplied completion handler, either
    /// synchronously or asynchronously.
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
    public func completedSync(_ result: T) -> SyncCompletionStatus {
        guard self.completionStatus == nil else {
            flintUsageError("Only one of completedSync() or willCompleteLater() can be called")
        }
        
        let completionStatus = SyncCompletionStatus()
        callCompletion(result, callingAsync: false)
        self.completionStatus = completionStatus
        return completionStatus
    }

    private func callCompletion(_ result: T, callingAsync: Bool) {
        guard let completion = completionHandler else {
            flintBug("There is no completion handler closure set")
        }
        completion(result, callingAsync)
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
    override public func willCompleteAsync() -> DeferredStatus {
        let _ = proxiedCompletion.willCompleteAsync()
        return super.willCompleteAsync()
    }
    
    /// The proxy calls its own `completedAsync` in order to execute the custom value modification logic,
    /// and that will in fact call the original completion's `completedSync`.
    override public func completedSync(_ result: T) -> SyncCompletionStatus {
        let result = super.completedSync(result)
        guard let proxiedStatus = proxiedCompletion.completionStatus, !proxiedStatus.isCompletingAsync else {
            flintBug("Sync completion on proxied completion requirement did not store the proxied status")
        }
        return result
    }
}
