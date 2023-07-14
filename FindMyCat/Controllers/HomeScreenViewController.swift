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

    private var mapboxView: MapboxView!

    private var deviceBottomDrawerViewController: DeviceBottomDrawerController!

    override func viewDidLoad() {
          super.viewDidLoad()
          showMainScreen()
        NotificationCenter.default.addObserver(self, selector: #selector(devicesUpdated(_:)), name: Notification.Name(Constants.DevicesUpdatedNotificationName), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        BLEDataCommunicationChannel.shared.start()
    }

    @objc private func devicesUpdated(_ notification: Notification) {

        // Update UI using the updated devices array
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
