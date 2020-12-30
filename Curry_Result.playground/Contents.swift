//
//  Curry_Semigroup.playground
//
//  Created by Hans Hsu on 2020/12/1.
//  Copyright © 2020 Hans Hsu. All rights reserved.
//

import UIKit

// The example is to use curry api with Result. It can inject parameter by async way.

// Ticket generator
typealias TickGenerator = (String) -> (String) -> (String) -> () -> TicketInfo

struct TicketInfo {
    let from: String
    let destination: String
    let transportation: String
}

extension TicketInfo : CustomStringConvertible {
    var description: String {
        return "The ticket info is from: \(from) to: \(destination) by \(transportation)."
    }
}

class TicketBuilder { }

extension TicketBuilder {
    class func getTicketGenerator() -> TickGenerator {
        return {
            (from) in {
                (destination) in {
                    (transportation) in {
                        .init(from: from, destination: destination, transportation: transportation)
                    }
                }
            }
        }
    }
}

// Error for enter failed
enum TicketError : Error {
    case incorrectInfo
}

extension TicketError : CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .incorrectInfo:
            return "Enter incorrect information"
        }
    }
}

// Custom result
enum Result<T, E : Error> {
    case success(T)
    case failed(E)
}

// Add pure , error , map , flatMap , apply api
extension Result {
    static func pure(_ object: T) -> Result<T, E> {
        return .success(object)
    }
    
    static func error(_ error: E) -> Result<T, E> {
        return .failed(error)
    }
    
    func map<O>(_ transform:(T) -> O) -> Result<O, E> {
        switch self {
        case let .success(value):
            return .success(transform(value))
        case .failed(let error):
            return .failed(error)
        }
    }
    
    func flatMap<O>(_ transform:(T) -> Result<O, E>) -> Result<O, E> {
        switch self {
        case let .success(value):
            return transform(value)
        case .failed(let error):
            return .failed(error)
        }
    }
    
    func apply<O>(_ tranform:Result<(T) -> O, E>) -> Result<O, E> {
        switch tranform {
        case let .success(tFunc):
            return map(tFunc)
        case .failed(let error):
            return .failed(error)
        }
    }
}

// Cutsom operator for Result
infix operator <^>:AdditionPrecedence

func <^><T, U, E>(lhs:(T) -> U , rhs:Result<T, E>) -> Result<U, E> {
    return rhs.map(lhs)
}

infix operator <*>:AdditionPrecedence

func <*><T, U, E>(lhs:Result<(T) -> U, E> , rhs:Result<T, E>) -> Result<U, E> {
    return rhs.apply(lhs)
}

// Cutsom Result for Ticket.
typealias TicketResult<T> = Result<T, TicketError>

// Example to use TicketBuilder and TicketResult by async way.

// Correct flow to enter information, this flow is also run in async flow.
let ticketGenerator = TicketBuilder.getTicketGenerator() <^> TicketResult.success("Taipei") <*> TicketResult.success("Kaohsiung") <*> TicketResult.success("Train")

if case .success(let generator) = ticketGenerator {
    let ticketInfo = generator()
    print(ticketInfo.description)
}

// Incorrect flow to enter incorrect information
let errorGenerator = TicketBuilder.getTicketGenerator() <^> TicketResult.failed(.incorrectInfo) <*> TicketResult.success("Kaohsiung") <*> TicketResult.success("Train")

if case .failed(let error) = errorGenerator {
    print(error.debugDescription)
}



