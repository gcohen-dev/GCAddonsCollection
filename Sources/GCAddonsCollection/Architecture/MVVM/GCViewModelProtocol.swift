//
//  File.swift
//  
//
//  Created by Guy Cohen on 17/07/2020.
//

import Foundation

protocol GCViewModelProtocol: ObservableObject where ObjectWillChangePublisher.Output == Void {
    associatedtype State
    associatedtype Input
    var state: State { get }
    func action(_ input: Input)
}
