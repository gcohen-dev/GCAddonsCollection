//
//  File.swift
//  
//
//  Created by Guy Cohen on 19/06/2020.
//

import Foundation
import UIKit


protocol GCMVPLifecycleProtocol : AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func viewWillDisappear()
}

extension GCMVPLifecycleProtocol {
    func viewDidLoad() {}
    func viewWillAppear() {}
    func viewWillDisappear() {}
}

class GCMVPBaseViewController<T: GCMVPLifecycleProtocol>: UIViewController {
    
    var presenter:T!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(presenter != nil, "Presenter has to be set")
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.viewWillDisappear()
    }
    
}
