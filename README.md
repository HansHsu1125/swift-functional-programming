# Swift Functional Programming
This is my simple example for functional programming of Swift. These cases are simple demo , it just used to display how to design the architecture. If you want to use it of your project , you need to implement more features.

## Curry with Result
The case is use Curry with Result to genenrate object.

### Example

```
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

Result ==============>
The ticket info is from: Taipei to: Kaohsiung by Train.
Enter incorrect information
```

## Pipeline

The case is focus to composite different task as pipeline to verify input value.

### Example

```
// Default task is verify nil value
let pipelineManager:PipelineManager<PipelineTask<String?>> = .init {
    $0 == nil
}

// Append verfiy emplty task
let verifyEmptyTask:PipelineTask<String?> = .init {
    ($0?.isEmpty == true)
}
pipelineManager.append(verifyEmptyTask)

// Append verfiy limitation task
let limitation:Int = 10
let verifyOverLimitationTask:PipelineTask<String?> = .init {
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

Result ==============>
===== verify nil value =====
result is nil
===== verify empty value =====
result is empty
===== verify value is over limitation of 10 =====
result is over limitation
===== verify value is over limitation of 10 =====
result is not over limitation

```

## Promise_then

The case is focus on how to execute async task via the then and delay api ( just like Promise ).

### Example - then
```
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

Result ==============>
the value is 50

```

### Example - delay

```
Promise.init { (callback) in
    callback(10)
}.then { (value) -> Int in
    return value + 20
}.delay(5) { (value) -> Int in
    return value + 100
}.then { (value) in
    print("the value is \(value)")
}

Result ==============>
the value is 130

```

## Signal

The case is focus on how to notify event by observer.

### Example
```
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

Result ==============>
observer 1 ========
subcrise to get value : 2
observer 2 ========
subcrise to get value : 2
observer 1 ========
subcrise to get value : 4
observer 2 ========
subcrise to get value : 4
observer 1 ========
subcrise to get value : 6
observer 2 ========
subcrise to get value : 6
observer 1 ========
subcrise to ger error : network failed
observer 2 ========
subcrise to ger error : network failed
```

## Group Tasks

The case is focus on how to executes tasks concurrently and wait all tasks complete to execute final task.

### Example

```
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

Result ==============>
execute step 1-1
execute step 2-1
execute step 3-1
execute step 3-2
execute step 2-2
execute step 1-2
await to execute totalVaule : 60
```

## Once

The case is design for once task , just like dispatch_once

### Example

```
let token = "123"
var count = 1
func printCountValue() {
    DispatchQueue.once(token: token) { (_) in
        print("print count value \(count)")
    }
}

printCountValue()

count += 1
printCountValue()

DispatchQueue.once(remove: token)
count += 1
printCountValue()

Result ==============>
print count value 1
print count value 3
```
