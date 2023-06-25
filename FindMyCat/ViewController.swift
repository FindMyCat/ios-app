//
//  ViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import UIKit
import MapboxMaps


class ViewController: UIViewController {
    

        
    private func showLoginScreen() {
      let loginViewController = LoginViewController()
      
      loginViewController.modalPresentationStyle = .fullScreen
      present(loginViewController, animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.showLoginScreen()
    }
}

