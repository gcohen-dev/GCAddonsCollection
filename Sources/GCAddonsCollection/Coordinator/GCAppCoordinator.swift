//
//  File.swift
//  
//
//  Created by Guy Cohen on 06/07/2020.
//

import Foundation
import UIKit
/**
  - Snippet Example of how is should be used
 
 class SceneDelegate: UIResponder, UIWindowSceneDelegate {

     var window: UIWindow?
     var app: GCApplicationCoordinator?

     func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
         guard let scene = (scene as? UIWindowScene) else { return }
         let window = UIWindow(windowScene: scene)
         app = GCApplicationCoordinator(window, firstSubCoordinator: HomeCoordinator.self)
         app?.start()
     }

 }
 */
public class GCApplicationCoordinator: GCCoordinator {
    
    let window: UIWindow
    let rootViewController: UINavigationController
    var firstSubCoordinator: GCCoordinatorChild
    var prefersLargeTitles = true
    
    public init(_ window: UIWindow, firstSubCoordinator: GCCoordinatorChild.Type) {
        self.window = window
        rootViewController = UINavigationController()
        if #available(iOS 11.0, *) {
            rootViewController.navigationBar.prefersLargeTitles = prefersLargeTitles
        } else { /** Fallback on earlier versions */ }
        self.firstSubCoordinator = firstSubCoordinator.init(rootViewController)
    }
    
    public func start() {
        window.rootViewController = rootViewController
        firstSubCoordinator.start()
        window.makeKeyAndVisible()
    }
    
}
