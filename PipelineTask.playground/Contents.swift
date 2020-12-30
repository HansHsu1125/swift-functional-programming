//
//  Pipeline.playground
//
//  Created by Hans Hsu on 2020/12/2.
//  Copyright © 2020 Hans Hsu. All rights reserved.
//

import UIKit

// Custom operator for pipeline
infix operator <> : DefaultPrecedence
typealias PipelineHandler<T> = (T) -> Bool

// Pipeline protocol
protocol Piplineable {
    associatedtype DataType
    init(_ pipelineHandler:@escaping PipelineHandler<DataType>)
    func execute(_ data: DataType) -> Bool
    static func <>(lhs: Self , rhs: Self) -> Self
}

// Defualt implement
extension Piplineable {
    func execute(_ data: DataType) -> Bool {
        print("\(#function) this is default implement")
        return false
    }
    
    static func <> (lhs: Self , rhs: Self) -> Self {
        return .init { lhs.execute($0) || rhs.execute($0) }
    }
}

// Struct for pipeline task
struct PipelineTask<T> {
    typealias DataType = T
    let handler: PipelineHandler<T>
    
    init(_ pipelineHandler: @escaping PipelineHandler<T>) {
        handler = pipelineHandler
    }
}

// Implement Piplineable protocol of PipelineTask
extension PipelineTask : Piplineable {
    func execute(_ data: DataType) -> Bool {
        return handler(data)
    }
}

// PipelineTaskManager control pipeline task
class PipelineManager<T: Piplineable> {
    typealias DataType = T.DataType
    var mainTask:T
    
    required init(_ pipelineHandler: @escaping PipelineHandler<T.DataType>) {
        mainTask = .init(pipelineHandler)
    }
}

// Implement Piplineable protocol of PipelineTaskManager
extension PipelineManager : Piplineable {
    func execute(_ data: T.DataType) -> Bool {
        return mainTask.execute(data)
    }
}

// Add append api
extension PipelineManager {
    func append<U : Piplineable>(_ task: U) -> Bool where U.DataType == T.DataType {
        guard let transformTask = task as? T else {
            return false
        }

        mainTask = mainTask <> transformTask
        return true
    }
}

extension String {
    func isLengthOverLimitation(_ limitation: Int) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard count > limitation else {
            return false
        }
        
        return true
    }
}

//Example for verify value by PipelineManager

// Default task is verify nil value
let pipelineManager: PipelineManager<PipelineTask<String?>> = .init {
    $0 == nil
}

// Append verfiy emplty task
let verifyEmptyTask: PipelineTask<String?> = .init {
    ($0?.isEmpty == true)
}
pipelineManager.append(verifyEmptyTask)

// Append verfiy limitation task
let limitation: Int = 10
let verifyOverLimitationTask: PipelineTask<String?> = .init {
    $0?.isLengthOverLimitation(10) == true
}
pipelineManager.append(verifyOverLimitationTask)

print("===== verify nil value =====")
print("result is \(pipelineManager.execute(nil) ? "nil" : "not nil")")

print("===== verify empty value =====")
print("result is \(pipelineManager.execute("") ? "empty" : "not empty")")

print("===== verify value is over limitation of 10 =====")
print("result is \(pipelineManager.execute("1000000000000") ? "over limitation" : "not over limitation")")

print("===== verify value is over limitation of 10 =====")
print("result is \(pipelineManager.execute("10000") ? "over limitation" : "not over limitation")")

