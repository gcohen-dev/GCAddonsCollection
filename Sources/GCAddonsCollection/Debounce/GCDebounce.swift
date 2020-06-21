//
//  File.swift
//  
//
//  Created by Guy Cohen on 21/06/2020.
//

import Foundation


public protocol GCDebounceable : AnyObject {
    
    /// Callback that will invoke when timer fires
    var callback: (() -> ())? { get set }
    
    /// Call debouncer to start the callback after the delayed time. Multiple calls will ignore the older calls and overwrite the firing time
    func call()
    
    /// We can set the queue we want the call back to be invoked, this is optionally
    /// - Parameter callerQueue: The queue which the call back will be invoked
    var callerQueue: DispatchQueue? { get set }
}


public class GCDebounce: NSObject, GCDebounceable {

    public var callback: (() -> ())?
    
    /// Delay Time in seconds
    private let delay: TimeInterval
    
    /// Timer to fire the callback event
    private var timer: DispatchSourceTimer?
    
    public var callerQueue: DispatchQueue?
    
    /// Init with delay time as argument, callback can be set later
    ///
    /// - Parameters:
    ///   - delay: delay in seconds
    ///   - dispatchQueue: the thread we should retrieve our callback
    public init(delay: TimeInterval){
        self.delay = delay
    }

    /// Init with delay time and callback as arguments
    ///
    /// - Parameters:
    ///   - delay: delay in seconds
    ///   - dispatchQueue: the thread we should retrieve our callback
    ///   - callback: the call back that should be invoked
    public init(delay: TimeInterval,
                callerQueue:DispatchQueue? = nil,
                callback: (() -> ())? = nil){
        self.delay = delay
        self.callback = callback
        self.callerQueue = callerQueue
    }
    
    public func call() {
        /// Cancel timer, if already running
        timer?.setEventHandler(handler: nil)
        timer?.cancel()
        /// If we do not have a callback we should not schedule anything
        guard callback != nil else { return }
        
        let isMainThread = Thread.current == Thread.main
        /// Reset timer to fire next event
        let queue = callerQueue ?? DispatchQueue(label: "sfg.debounce.timer.\(UUID.init().uuidString)")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now() + delay)
        timer?.setEventHandler(handler: { [weak self] in
            if isMainThread {
                DispatchQueue.main.async {
                    self?.callback?()
                }
            } else {
                self?.callback?()
            }
        })
        timer?.resume()
    }
}
