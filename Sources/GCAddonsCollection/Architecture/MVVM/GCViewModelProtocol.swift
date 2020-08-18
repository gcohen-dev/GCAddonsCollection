//
//  File.swift
//  
//
//  Created by Guy Cohen on 17/07/2020.
//

import Foundation

@available(iOS 13.0, *)
protocol GCViewModelProtocol: ObservableObject where ObjectWillChangePublisher.Output == Void {
    associatedtype State
    associatedtype Input
    var state: State { get }
    func action(_ input: Input)
}
