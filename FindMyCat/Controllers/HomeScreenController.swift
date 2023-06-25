//
//  HomeScreenController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation
import UIKit

class HomeScreenController: UIViewController {
    private var mapboxView: MapboxView!
    
    private var deviceBottomDrawerViewController: DeviceBottomDrawerController!
    
    override func viewDidLoad() {
        showMainScreen()
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
