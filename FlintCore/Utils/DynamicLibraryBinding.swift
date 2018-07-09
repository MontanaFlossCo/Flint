//
//  DynamicLibraryBinding.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/07/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//
import Foundation

enum DynamicBindError: Error {
    case classNotFound
    case methodNotFound
}

/// Test if a class can be loaded from a given library.
func libraryIsLinkedForClass(_ className: String) -> Bool {
    return NSClassFromString(className) != nil
}

func instantiate(classNamed className: String) throws -> NSObject {
    guard let targetClass = NSClassFromString(className) as? NSObject.Type else {
        throw DynamicBindError.classNotFound
    }
    return targetClass.init()
}

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

//
//func dynamicBind(toInstance object: AnyObject, selector: Selector) throws -> DynamicInvocation {
//    guard let method = object.method(for: selector) else {
//        throw DynamicBindError.methodNotFound
//    }
//    return DynamicInvocation(instance: object, method: method, selector: selector)
//}
//
//func dynamicBindIntReturn(toStaticMethod methodName: String, on className: String) throws -> () -> Int {
//    let invocation = try DynamicInvocation(className: className, staticMethodName: methodName)
//    return {
//        typealias FuncType = @convention(c) (AnyObject, Selector) -> Int
//        return invocation.perform { (functionGenerator: () -> FuncType, instance, selector) in
//            let function: FuncType = functionGenerator()
//            return function(instance, selector)
//        }
//    }
//}
//
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
//
//func dynamicBindUIntArgsIntReturn(toStaticMethod methodName: String, on className: String) throws -> (UInt) -> Int {
//    let invocation = try DynamicInvocation(className: className, staticMethodName: methodName)
//    return { (arg1: UInt) in
//        typealias FuncType = @convention(c) (AnyObject, Selector, UInt) -> Int
//        return invocation.perform { (functionGenerator: () -> FuncType, instance, selector) in
//            let function: FuncType = functionGenerator()
//            return function(instance, selector, arg1)
//        }
//    }
//}
//
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
//
//func dynamicBindUIntAndBoolErrorOptionalClosureReturnVoid(toInstanceMethod methodName: String, on object: AnyObject) throws -> (UInt, (Bool, Error?) -> Void) -> Void {
//    let invocation = try DynamicInvocation(object: object, methodName: methodName)
//    return { (arg1: UInt, arg2: (Bool, Error?) -> Void) in
//        typealias FuncType = @convention(c) (AnyObject, Selector, UInt, (Bool, Error?) -> Void) -> Void
//        invocation.perform { (functionGenerator: () -> FuncType, instance, selector) in
//            let function: FuncType = functionGenerator()
//            function(instance, selector, arg1, arg2)
//        }
//    }
//}
//
///// Support zero-arg instance function.
///// Input/output func type is: () -> T
///// Internally we current the instance and selector, and return a func that has these bound
//func dynamicBindVoidReturn(toInstanceMethod methodName: String, on object: AnyObject) throws -> () -> Void {
//    let invocation = try DynamicInvocation(object: object, methodName: methodName)
//    return {
//        typealias FuncType = @convention(c) (AnyObject, Selector) -> Void
//        invocation.perform { (functionGenerator: () -> FuncType, instance, selector) in
//            let function: FuncType = functionGenerator()
//            function(instance, selector)
//        }
//    }
//}
//
//func dynamicBindIntReturn(toInstanceMethod methodName: String, on object: AnyObject) throws -> () -> Int {
//    let selector = NSSelectorFromString(methodName)
//    guard let method = object.method(for: selector) else {
//        throw DynamicBindError.methodNotFound
//    }
//
//    typealias funcType = @convention (c) (AnyObject, Selector) -> Int
//    let dynamicFunction: funcType = unsafeBitCast(method, to: funcType.self)
//    return {
//        return dynamicFunction(object, selector)
//    }
//}
