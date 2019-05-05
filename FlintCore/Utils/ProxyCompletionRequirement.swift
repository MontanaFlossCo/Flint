//
//  ProxyCompletionRequirement.swift
//  FlintCore
//
//  Created by Marc Palmer on 05/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A `ProxyCompletionRequirement` allows you to provide a completion requirement that adds some custom completion logic
/// to an existing completion instance, and then return a possibly modified result value to the original requirement.
///
/// This mechanism allows your code to "not care" whether the completion you are proxying is called synchronously or not.
/// Normally you need to know if completion you are wrapping would be called async or not, as you would need to
/// capture the async completion status before defining your completion block so it can call `completed` on the async result.
///
/// This is a bit nasty in the nuance of the implementation. We may remove this if `addProxyCompletionHandler`
public class ProxyCompletionRequirement<T>: CompletionRequirement<T> {
    var proxiedCompletion: CompletionRequirement<T>
    
    public init(proxying originalCompletion: CompletionRequirement<T>, proxyCompletionHandler: @escaping ProxyHandler) {
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
