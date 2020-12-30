//
//  Signal.playground
//  FuncTest
//
//  Created by Hans Hsu on 2020/12/11.
//  Copyright © 2020 Hans Hsu. All rights reserved.
//

import UIKit

var str = "Hello, playground"

typealias EventHandler<E> = (Event<E>) -> ()

enum Event<Element> {
    case next(Element)
    case failed(Error)
}

protocol Observerable {
    associatedtype Event
    init(_ action: @escaping EventHandler<Event>)
    func sendNext(_ element: Event)
    func sendError(_ error: Error)
}

struct Observer<E> {
    private let _action: EventHandler<Event>
    
    init(_ action: @escaping EventHandler<Event>) {
        _action = action
    }
}

extension Observer : Observerable {
    typealias Event = E
    
    func sendNext(_ element: Event) {
        _action(.next(element))
    }
    
    func sendError(_ error: Error) {
        _action(.failed(error))
    }
}

protocol Signalable {
    associatedtype Event
    associatedtype ObserverType: Observerable
    
    var observer: ObserverType? { get }
    init(_ value: Event)
    func subcrise(_ next: ((Event) -> ())? , _ error: ((Error) -> ())?)
}

class Signal<E> {
    private var _value: Event?
    private var _observer: ObserverType?

    required init(_ value: Event) {
        _value = value
    }
}

extension Signal : Signalable {
    typealias Event = E
    typealias ObserverType = Observer<Event>
    
    var observer: ObserverType? {
        return _observer
    }
    
    func subcrise(_ next: ((Event) -> ())? = nil , _ error: ((Error) -> ())? = nil) {
        let originalObserver = _observer
        _observer = .init({ (event) in
            switch event {
            case .next(let event):
                originalObserver?.sendNext(event)
                next?(event)
            case .failed(let err):
                originalObserver?.sendError(err)
                error?(err)
            }
        })
    }
}

enum ParseError : Error {
    case network_failed(String)
}

extension ParseError : CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .network_failed(let errString):
            return errString
        }
    }
}

let signal = Signal.init(5)

signal.subcrise({ (value) in
    print("observer 1 ========")
    print("subcrise to get value : \(value)")
}) { (error) in
    if let parseError = error as? ParseError {
        print("observer 1 ========")
        print("subcrise to ger error : \(parseError.debugDescription)")
    }
}

signal.subcrise({ (value) in
    print("observer 2 ========")
    print("subcrise to get value : \(value)")
}) { (error) in
    if let parseError = error as? ParseError {
        print("observer 2 ========")
        print("subcrise to ger error : \(parseError.debugDescription)")
    }
}

let observer = signal.observer

DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
    observer?.sendNext(2)
}

DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
    observer?.sendNext(4)
}

DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3) {
    observer?.sendNext(6)
}

DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 4) {
    observer?.sendError(ParseError.network_failed("network failed"))
}


