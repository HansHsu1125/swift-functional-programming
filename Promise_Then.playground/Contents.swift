//
//  Promise_Then.playground
//
//  Created by Hans Hsu on 2020/11/30.
//  Copyright © 2020 Hans Hsu. All rights reserved.
//

import UIKit

/*
 This is sample to execute async task via the then api. You need to do more feature if you want use it in your project. ( like multi thread , thread thread , retain cycle , life cycle of Promise , error handling etc )
 */

var str = "Hello, playground"

typealias PromiseHandler<T> = (@escaping (T) -> ()) -> ()

class Promise<R> {
    fileprivate let promiseHandler: PromiseHandler<R>

    init(_ handler: @escaping PromiseHandler<R>) {
        promiseHandler = handler
    }
}

// Add map , flatMap , apply api
extension Promise {
    fileprivate func map<U>(_ handler: @escaping (R) -> U) -> Promise<U> {
        let semaphore = DispatchSemaphore(value: 0)
        var newValue: U?
        promiseHandler { value in
            newValue = handler(value)
            semaphore.signal()
        }
        
        return .init { closure in
            semaphore.wait()
            if let value = newValue {
                closure(value)
            }
        }
    }
    
    fileprivate func map<U>(delay timer: TimeInterval , handler: @escaping (R) -> U) -> Promise<U> {
        let semaphore = DispatchSemaphore(value: 0)
        var newValue:U?
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timer) {
            self.promiseHandler { value in
                newValue = handler(value)
                semaphore.signal()
            }
        }

        return .init { closure in
            semaphore.wait()
            if let value = newValue {
                closure(value)
            }
        }
    }
    
    fileprivate func flatMap<U>(_ handler: @escaping (R) -> Promise<U>) -> Promise<U> {
        let semaphore = DispatchSemaphore(value: 0)
        var promise: Promise<U>?
        promiseHandler { value in
            promise = handler(value)
            semaphore.signal()
        }

        return .init { closure in
            semaphore.wait()
            promise?.then({ (value) in
                closure(value)
            })
        }
    }
}

// Add delay , then api
extension Promise {
    func delay<U>(_ timer: TimeInterval  , _ handler: @escaping (R) -> U) -> Promise<U> {
        return map(delay: timer, handler:handler)
    }
    
    func then(_ handler: @escaping (R) -> ()) {
        promiseHandler { value in
            handler(value)
        }
    }
    
    func then<U>(_ handler: @escaping (R) -> Promise<U>) -> Promise<U> {
        return flatMap(handler)
    }
    
    func then<U>(_ handler: @escaping (R) -> U) -> Promise<U> {
        return map(handler)
    }
}

// Example for Promise
let initialValue = 10
Promise.init { (callback) in
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
        callback(initialValue)
    }
}.then { (value) -> Promise<Int> in
    return .init { callback in
        let newValue = value + 10
        callback(newValue)
    }
}.then { (value) -> Promise<Int> in
    return .init { (callback) in
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
            let newValue = value + 10
            callback(newValue)
        }
    }
}.then { (value) -> Int in
    return value + 20
}.then { (value) in
    print("the value is \(value)")
}

// For delay
Promise.init { (callback) in
    callback(10)
}.then { (value) -> Int in
    return value + 20
}.delay(5) { (value) -> Int in
    return value + 100
}.then { (value) in
    print("the value is \(value)")
}


