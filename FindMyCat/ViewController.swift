//
//  ViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import UIKit
import MapboxMaps


class ViewController: UIViewController {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        showMainOrLoginScreen()
    }
    
    private func showMainOrLoginScreen() {
        TraccarAPIManager.shared.getSession {
            response in
            
            switch response {
            case .success(let session):
                print("Session found : ", session)
                self.showMainScreen()
            case .failure(_):
                print("No session found, redirecting to login screen")
                self.showLoginScreen()
            }
        }
    }
    
    private func showLoginScreen() {
      let loginViewController = LoginViewController()
      
      loginViewController.modalPresentationStyle = .fullScreen
      present(loginViewController, animated: true, completion: nil)
    }
    
    private func showMainScreen() {
      let homeScreenController = HomeScreenController()
      
      homeScreenController.modalPresentationStyle = .fullScreen
      present(homeScreenController, animated: true, completion: nil)
    }

}

