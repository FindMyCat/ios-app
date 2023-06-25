//
//  HomeScreenController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation
import UIKit
import Combine

class HomeScreenController: UIViewController {
    
    // Load devices here from API
    private var devices: [Device] = []
    
    private var mapboxView: MapboxView!
    
    private var deviceBottomDrawerViewController: DeviceBottomDrawerController!

    
    override func viewDidLoad() {
          super.viewDidLoad()
          fetchDevices()
          showMainScreen()
      }

    private func fetchDevices() {
        TraccarAPIManager.shared.fetchDevices { [weak self] response in
            switch response {
            case .success(let devices):
                self?.devices = devices
            case .failure(let error):
                print("Could not fetch devices", error)
            }
        }
    }
    

    
    private func showMainScreen() {
          // Add map to the background
          mapboxView = MapboxView(frame: view.bounds)
          view.addSubview(mapboxView)
          
          // Add bottom sheet to the bottom
          deviceBottomDrawerViewController = DeviceBottomDrawerController(parentView: view, parentVc: self)
        
          view.addSubview(deviceBottomDrawerViewController.view)
      }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapboxView?.frame = view.bounds
        deviceBottomDrawerViewController?.view.frame = view.bounds
    }
    
}
