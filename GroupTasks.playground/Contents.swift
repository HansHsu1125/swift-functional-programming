//
//  GroupsTasks.playground
//
//  Created by Hans Hsu on 2020/12/7.
//  Copyright © 2020 Hans Hsu. All rights reserved.
//

import UIKit

typealias CompleteHandler = () -> Void
typealias AsyncExecuteHandler = (@escaping CompleteHandler) -> Void

// AsyncExecuteable protocol
protocol AsyncExecuteable {
    init(_ pipelineHandler:@escaping AsyncExecuteHandler)
    func execute(_ handler:@escaping CompleteHandler)
}

// Struct for GroupTasks
struct GroupTasks {
    let handler:AsyncExecuteHandler
    
    init(_ asyncExecuteHandler:@escaping AsyncExecuteHandler) {
        handler = asyncExecuteHandler
    }
}

// Implement AsyncExecuteable protocol of PipelineTask
extension GroupTasks : AsyncExecuteable {
    func execute(_ conmpleteHandler:@escaping CompleteHandler) {
        handler(conmpleteHandler)
    }
}

// Define Awaitable to execute complete handler
protocol Awaitable {
    func await(_ queue:DispatchQueue , _ completeHandler:@escaping CompleteHandler)
}

// Define Groupable to bind tasks
protocol Groupable: Awaitable {
    init(_ group:DispatchGroup , _ handler:@escaping AsyncExecuteHandler)
    func bind(Task task:@escaping AsyncExecuteHandler) -> Self
}

// GroupTasksManager to control group tasks
struct GroupTasksManager {
    let groups:DispatchGroup
    var mainTask:GroupTasks
    
    init(_ group:DispatchGroup = .init() , _ handler:@escaping AsyncExecuteHandler) {
        groups = group
        mainTask = .init(handler)
    }
    
    private func execute() {
        groups.enter()
        mainTask.execute {
            groups.leave()
        }
    }
}

// Implement Groupable
extension GroupTasksManager: Groupable {
    func bind(Task task:@escaping AsyncExecuteHandler) -> Self {
        let newTask:GroupTasks = .init(task)

        return .init(groups) { clourse in
            execute()
            newTask.execute(clourse)
        }
    }
}

// Implement Awaitable
extension GroupTasksManager: Awaitable {
    func await(_ queue:DispatchQueue = .global() , _ completeHandler:@escaping CompleteHandler) {
        execute()
        groups.notify(queue: queue) {
            completeHandler()
        }
    }
}

// Exapmle for run async task and bind together
var totalVaule = 0

GroupTasksManager.init { (clouse) in
    print("execute step 1-1")
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 10) {
        print("execute step 1-2")
        totalVaule += 10
        clouse()
    }
}.bind { (clouse) in
    print("execute step 2-1")
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 7) {
        print("execute step 2-2")
        totalVaule += 20
        clouse()
    }
}.bind { (clouse) in
    print("execute step 3-1")
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
        print("execute step 3-2")
        totalVaule += 30
        clouse()
    }
}.await {
    print("await to execute totalVaule : \(totalVaule)")
}
