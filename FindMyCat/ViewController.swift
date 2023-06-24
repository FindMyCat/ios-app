//
//  ViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import UIKit
import MapboxMaps


class ViewController: UIViewController {
    private var mapboxView: MapboxView!
    
    private var deviceBottomDrawerViewController: DeviceBottomDrawerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // Add map to the background
        mapboxView = MapboxView(frame: view.bounds)
        self.view.addSubview(mapboxView)
        
        // Add bottom sheet to the bottom
        deviceBottomDrawerViewController = DeviceBottomDrawerController(parentView: view, parentVc: self)
        
        self.view.addSubview(deviceBottomDrawerViewController.view)
    }
    
    
    // TODO: Do we need this?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapboxView.frame = view.bounds
        deviceBottomDrawerViewController.view.frame = view.bounds
    }
}

