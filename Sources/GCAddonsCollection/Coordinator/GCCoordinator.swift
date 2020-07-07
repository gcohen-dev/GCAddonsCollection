//
//  File.swift
//  
//
//  Created by Guy Cohen on 06/07/2020.
//

import Foundation
import UIKit

public protocol GCCoordinator {
    func start()
}

public protocol GCCoordinatorChild: GCCoordinator {
    init(_ navigation: UINavigationController)
}
