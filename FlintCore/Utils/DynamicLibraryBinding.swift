//
//  DynamicLibraryBinding.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//
import Foundation

/// The error type for dynamic binding failures.
enum DynamicBindError: Error {
    /// There was no class found for the given name
    case classNotFound
    
    /// There was no method found for the selector name specified
    case methodNotFound
}

/// Test if a class can be loaded from a given library.
func libraryIsLinkedForClass(_ className: String) -> Bool {
    return NSClassFromString(className) != nil
}

/// Instantiate an Objective-C compatible class using a default no-arg initialiser, by name.
/// - param className: The name of the class to instantiate
func instantiate(classNamed className: String) throws -> NSObject {
    guard let targetClass = NSClassFromString(className) as? NSObject.Type else {
        throw DynamicBindError.classNotFound
    }
    return targetClass.init()
}

/// A wrapper around the horrific unsafeBitCast stuff we need to do to bind Swift functions to ObjC methods
/// resolved dynamically at runtime.
struct DynamicInvocation {
    let instance: AnyObject
    let method: IMP
    let selector: Selector

    init(instance: AnyObject, method: IMP, selector: Selector) {
        self.instance = instance
        self.method = method
        self.selector = selector
    }

    init(className: String, staticMethodName: String) throws {
        guard let targetClass = NSClassFromString(className) else {
            throw DynamicBindError.classNotFound
        }
        instance = targetClass
        selector = NSSelectorFromString(staticMethodName)
        guard let method = targetClass.method(for: selector) else {
            throw DynamicBindError.methodNotFound
        }
        self.method = method
    }

    init(object: AnyObject, methodName: String) throws {
        instance = object
        selector = NSSelectorFromString(methodName)
        guard let method = object.method(for: selector) else {
            throw DynamicBindError.methodNotFound
        }
        self.method = method
    }

    func perform<T, ReturnType>(block: (_ functionGenerator: () -> T, _ instance: AnyObject, _ selector: Selector) -> ReturnType) -> ReturnType where T: Any {
        let f: () -> T = {
            return unsafeBitCast(self.method, to: T.self)
        }
        return block(f, instance, selector)
    }
}

/// Returns a function that will call the specified static Objective-C method on the class specified by name, taking an
/// Int argument and returning an Int result.
///
/// - param methodName: The Objective-C method/selector name
/// - param className: The Objective-C class name e.g. `CNContactStore`
func dynamicBindIntArgsIntReturn(toStaticMethod methodName: String, on className: String) throws -> (Int) -> Int {
    let invocation = try DynamicInvocation(className: className, staticMethodName: methodName)
    return { (arg1: Int) in
        typealias FuncType = @convention(c) (AnyObject, Selector, Int) -> Int
        return invocation.perform { (functionGenerator: () -> FuncType, instance, selector) in
            let function: FuncType = functionGenerator()
            return function(instance, selector, arg1)
        }
    }
}

/// Returns a function that will call the specified Objective-C instance method on the object specified, taking an
/// Int argument and a closure argument (taking a Bool and Error?), and returning an Void result.
///
/// - param methodName: The Objective-C instance method/selector name
/// - param object: The Objective-C object instance on which to perform this method
func dynamicBindIntAndBoolErrorOptionalClosureReturnVoid(toInstanceMethod methodName: String, on object: AnyObject) throws -> (Int, (Bool, Error?) -> Void) -> Void {
    let invocation = try DynamicInvocation(object: object, methodName: methodName)
    return { (arg1: Int, arg2: (Bool, Error?) -> Void) in
        typealias FuncType = @convention(c) (AnyObject, Selector, Int, (Bool, Error?) -> Void) -> Void
        invocation.perform { (functionGenerator: () -> FuncType, instance, selector) in
            let function: FuncType = functionGenerator()
            function(instance, selector, arg1, arg2)
        }
    }
}

