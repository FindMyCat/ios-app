//
//  SharedData.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation
import Combine

class SharedData {
    static let shared = SharedData()
    
    private static var devices: [Device] = [] {
        didSet {
            print("devices set")
            let userInfo = ["devices": devices]
            NotificationCenter.default.post(name: Notification.Name(Constants.DevicesUpdatedNotificationName), object: nil, userInfo: userInfo)
        }
    }
    private static var positions: [Position] = [] {
        didSet {
            print("positions set")
            let userInfo = ["positions": positions]
            NotificationCenter.default.post(name: Notification.Name(Constants.PositionsUpdatedNotificationName), object: nil, userInfo: userInfo)
        }
    }
    
    // Websockets
    private let webSocketManager = WebSocketManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: Initialize function
    private init() {
        // Initialize WebSocket connection and handle incoming data updates
        // Update the devices array accordingly
        print("SharedData init()")
        configureWebsocket()
        fetchDevicesFromRestAPI()
     }
    
    // MARK: Getters for Devices and Position static variables
    public static func getDevices() -> [Device] {
        return self.devices
    }
    
    public static func getPositions() -> [Position] {
        return self.positions
    }
    
    // MARK: Network handlers
    private func fetchDevicesFromRestAPI() {
        print("fetching devices from REST API")
        TraccarAPIManager.shared.fetchDevices {
            result in
            
            switch result {
            case .success(let devices):
                // Set devices in shared data so it's acceccible to all consuming classes.
                SharedData.devices = devices
            case .failure(let error):
                print("Could not fetch Devices from REST endpoint ", error)
            }
        }
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
        
        let jsonData = jsonString.data(using: .utf8)!
        
        do {
            let decoder = JSONDecoder()
            let payloadWrapper = try decoder.decode(PayloadWrapper.self, from: jsonData)
            
            if let devices = payloadWrapper.devices {
//              // Update existing devices and append new devices
                for newDevice in devices {
                    if let index = SharedData.devices.firstIndex(where: { $0.id == newDevice.id }) {
                        // Device with the same ID exists, update it
                        SharedData.devices[index] = newDevice
                    } else {
                        // Device does not exist, append it
                        SharedData.devices.append(newDevice)
                    }
                }
            } else if let positions = payloadWrapper.positions {
                for newPosition in positions {
                    if let index = SharedData.positions.firstIndex(where: { $0.id == newPosition.id }) {
                        // Device with the same ID exists, update it
                        SharedData.positions[index] = newPosition
                    } else {
                        // Device does not exist, append it
                        SharedData.positions.append(newPosition)
                    }
                }
            }
        } catch {
            print("Error decoding JSON: \(error)")
        }
        
    }
}
