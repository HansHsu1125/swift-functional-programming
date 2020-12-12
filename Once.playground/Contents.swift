import UIKit

var str = "Hello, playground"

// Add once api of DispatchQueue
extension DispatchQueue {
    private static var lock = NSLock()
    private static var onceMap = Set<String>()
    
    class func once(file: String = #file, function: String = #function, line: Int = #line, block:(String)-> ()) {
        let token = file + ":" + function + ":" + String(line)
        once(token: token, block: block)
    }

    class func once(token: String, block:(String) -> ()) {
        defer { lock.unlock() }
        lock.lock()
        guard !onceMap.contains(token) else {
            return
        }
        
        onceMap.insert(token)
        block(token)
    }
    
    class func once(remove token: String) {
        defer { lock.unlock() }
        lock.lock()
        onceMap.remove(token)
    }
}

// Example for DispatchQueue.once
let token = "123"
var count = 1

func printCountValue() {
    DispatchQueue.once(token: token) { (_) in
        print("print count value \(count)")
    }
}

// Print initial value by once api to ensure that it only execute once.
printCountValue()

// It doesn't print value because it has already execute , the token is still exist.
count += 1
printCountValue()

// Remove token
DispatchQueue.once(remove: token)

// Print newest value
count += 1
printCountValue()
