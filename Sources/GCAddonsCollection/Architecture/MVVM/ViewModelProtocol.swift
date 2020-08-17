//
//  File.swift
//  
//
//  Created by Guy cohen on 18/08/2020.
//

import Foundation

protocol ViewModelProtocol: ObservableObject where ObjectWillChangePublisher.Output == Void {
    associatedtype State
    associatedtype Input
    var state: State { get }
    func action(_ input: Input)
}
