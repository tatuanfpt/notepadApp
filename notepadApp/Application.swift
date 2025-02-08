//
//  Application.swift
//  notepadApp
//
//  Created by TuanTa on 8/2/25.
//


import UIKit

final class Application {
    
    static let shared = Application()
    private init() {
        
    }
    
    func configureMainInterface(_ window: UIWindow = UIWindow()) {
        var expectViewController: UIViewController!
        expectViewController = UIViewController()
        expectViewController.title = "Notepad"
        expectViewController.view.backgroundColor = .green
        if let window = UIApplication.shared.windows.first {
            let navigationController = UINavigationController(rootViewController: expectViewController)
            window.rootViewController = navigationController
        }
        
    }
}
