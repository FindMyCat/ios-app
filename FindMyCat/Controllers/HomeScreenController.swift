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
    
    private var devices: [Device] = []
    
    private var deviceBottomDrawerViewController: DeviceBottomDrawerController!

    
    // Websockets
    private let webSocketManager = WebSocketManager()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
          super.viewDidLoad()
          showMainScreen()
          configureWebsocket()
      }
    
    private func configureWebsocket() {
        webSocketManager.connect()
        webSocketManager.dataPublisher
            .sink { [weak self] newData in
                self?.handleWebSocketData(newData)
            }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketData(_ jsonString: String) {
        // Handle updated data in the first view controller
        print("HomeScreenController websocket recv data: \(jsonString)")
        
        let jsonData = jsonString.data(using: .utf8)!
        print(jsonData)
        
        do {
            let decoder = JSONDecoder()
            let payloadWrapper = try decoder.decode(PayloadWrapper.self, from: jsonData)
            
            if let devices = payloadWrapper.devices {
                for device in devices {
                    print(device.name)
                }
                // Handle devices
            } else if let positions = payloadWrapper.positions {
                // Handle positions
                for position in positions {
                    print(position.longitude)
                }
            }
        } catch {
            print("Error decoding JSON: \(error)")
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
