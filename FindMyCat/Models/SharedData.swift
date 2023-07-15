//
//  SharedData.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation
import Combine
import os.log
class SharedData {
    static let shared = SharedData()

    let logger = Logger(subsystem: "Models", category: String(describing: SharedData.self))

    private static var devices: [Device] = [] {
        didSet {
            let userInfo = ["devices": devices]
            NotificationCenter.default.post(name: Notification.Name(Constants.DevicesUpdatedNotificationName), object: nil, userInfo: userInfo)
        }
    }
    private static var positions: [Position] = [] {
        didSet {
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

        // Sequentially exeute API calls and finally register websockets.
        fetchDevicesFromRestAPI {
            self.fetchPositionsFromRestAPI {
                self.configureWebsocket {
                   // Fetched complete.
                }
            }
        }

     }

    public func updateDataFromApi() {
        fetchDevicesFromRestAPI {
            self.fetchPositionsFromRestAPI {

            }
        }
    }

    // MARK: Getters for Devices and Position static variables
    public static func getDevices() -> [Device] {
        return self.devices
    }

    public static func getDevicesCount() -> Int {
        return self.devices.count
    }

    public static func getPositions() -> [Position] {
        return self.positions
    }

    // MARK: Network handlers
    private func fetchDevicesFromRestAPI(completion: @escaping () -> Void) {
        logger.log("fetching devices from REST API")
        TraccarAPIManager.shared.fetchDevices {
            result in

            switch result {
            case .success(let devices):
                // Set devices in shared data so it's acceccible to all consuming classes.
                SharedData.devices = devices
            case .failure(let error):
                self.logger.error("Could not fetch Devices from REST endpoint \(error)")
            }
            completion()
        }
    }

    private func fetchPositionsFromRestAPI(completion: @escaping () -> Void) {
        logger.log("fetching positions from REST API")
        TraccarAPIManager.shared.fetchPositions {
            result in

            switch result {
            case .success(let positions):
                // Set devices in shared data so it's acceccible to all consuming classes.
                SharedData.positions = positions
            case .failure(let error):
                self.logger.error("Could not fetch Devices from REST endpoint \(error)")
            }
            completion()
        }
    }

    private func configureWebsocket(completion: @escaping () -> Void) {
        webSocketManager.connect()
        webSocketManager.dataPublisher
            .sink { [weak self] newData in
                self?.handleWebSocketData(newData)
            }
            .store(in: &cancellables)
        completion()
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
                    if let index = SharedData.positions.firstIndex(where: { $0.deviceId == newPosition.deviceId }) {
                        // Device with the same ID exists, update it
                        SharedData.positions[index] = newPosition
                    } else {
                        // Device does not exist, append it
                        SharedData.positions.append(newPosition)
                    }
                }
            }
        } catch {
            logger.error("Error decoding JSON: \(error)")
        }

    }
}
