//
//  AsyncOperation.swift
//  lampv2
//
//  Created by ZCo Engg Dept on 14/01/20.

import Foundation

class AsyncOperation: Operation {
    override var isAsynchronous: Bool { return true }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }

    var state = State.ready {
        willSet {
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }
        didSet {
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }

    override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
            //Asynchronous logic (eg: n/w calls) with callback {
        }
    }
}
