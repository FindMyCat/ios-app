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
    private static var deviceStates: [Int: DeviceState] = [:] {
        didSet {
            let userInfo = ["deviceStates": deviceStates]
            NotificationCenter.default.post(name: Notification.Name(Constants.DeviceStatusUpdatedNotificationName), object: nil, userInfo: userInfo)
        }
    }
    /// Polls device-status only while a ping waits for its answer.
    private static var statePollTimer: Timer?
    private static let statePollInterval: TimeInterval = 3
    private static let STUCK_PING_TIMEOUT_EDRX_CYCLES: Double = 2
    private static let PINGS_IN_FLIGHT_PERSISTENCE_KEY = "PingsInFlightSentAtByDeviceId"
    private static var pingsInFlight: [Int: Date] = loadPersistedPingsInFlight() {
        didSet {
            persistPingsInFlight()
            let userInfo = ["pingsInFlight": pingsInFlight]
            NotificationCenter.default.post(name: Notification.Name(Constants.PingsInFlightUpdatedNotificationName), object: nil, userInfo: userInfo)
        }
    }

    // Websockets
    private let webSocketManager = WebSocketManager()
    private var cancellables = Set<AnyCancellable>()

    private static let localDevicesKey = "LocalDebugDevices"

    // MARK: Initialize function
    private init() {
        // Initialize WebSocket connection and handle incoming data updates
        // Update the devices array accordingly
        print("SharedData init()")

        // Sequentially exeute API calls and finally register websockets.
        fetchDevicesFromRestAPI {
            SharedData.mergeInPersistedLocalDevices()
            SharedData.devices.forEach { SharedData.fetchState(forDeviceId: $0.id) }
            if !SharedData.pingsInFlight.isEmpty {
                SharedData.startStatePolling()
            }
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

    public static func addLocalDevice(_ device: Device) {
        devices.append(device)
        persistLocalDevices()
    }

    private static func loadPersistedLocalDevices() -> [Device] {
        guard let data = UserDefaults.standard.data(forKey: localDevicesKey) else { return [] }
        return (try? JSONDecoder().decode([Device].self, from: data)) ?? []
    }

    private static func persistLocalDevices() {
        let locals = devices.filter { $0.id == 0 }
        if let data = try? JSONEncoder().encode(locals) {
            UserDefaults.standard.set(data, forKey: localDevicesKey)
        }
    }

    private static func mergeInPersistedLocalDevices() {
        let locals = loadPersistedLocalDevices()
        for local in locals where !devices.contains(where: { $0.uniqueId == local.uniqueId }) {
            devices.append(local)
        }
    }

    // Light color is kept on this phone only, keyed by the device uniqueId.
    private static let lightColorsKey = "LightColorByUniqueId"

    public static func lightColor(forUniqueId uniqueId: String) -> LightColor {
        let stored = UserDefaults.standard.dictionary(forKey: lightColorsKey)?[uniqueId] as? Int
        return stored.flatMap { LightColor(rawValue: UInt8($0)) } ?? .white
    }

    public static func setLightColor(_ color: LightColor, forUniqueId uniqueId: String) {
        var colors = UserDefaults.standard.dictionary(forKey: lightColorsKey) ?? [:]
        colors[uniqueId] = Int(color.rawValue)
        UserDefaults.standard.set(colors, forKey: lightColorsKey)
    }

    public static func getDevicesCount() -> Int {
        return self.devices.count
    }

    public static func getPositions() -> [Position] {
        return self.positions
    }

    public static func getDeviceState(forDeviceId deviceId: Int) -> DeviceState? {
        return deviceStates[deviceId]
    }

    public static func markPingSent(forDeviceId deviceId: Int) {
        pingsInFlight[deviceId] = Date()
        startStatePolling()
    }

    private static func loadPersistedPingsInFlight() -> [Int: Date] {
        guard let persistedPingsInFlightData = UserDefaults.standard.data(forKey: PINGS_IN_FLIGHT_PERSISTENCE_KEY) else { return [:] }
        return (try? JSONDecoder().decode([Int: Date].self, from: persistedPingsInFlightData)) ?? [:]
    }

    private static func persistPingsInFlight() {
        if let pingsInFlightData = try? JSONEncoder().encode(pingsInFlight) {
            UserDefaults.standard.set(pingsInFlightData, forKey: PINGS_IN_FLIGHT_PERSISTENCE_KEY)
        }
    }

    public static func pingSentAt(forDeviceId deviceId: Int) -> Date? {
        return pingsInFlight[deviceId]
    }

    public static func isLostModeOn(forDeviceId deviceId: Int) -> Bool {
        return deviceStates[deviceId]?.command?.command == "lost"
    }

    public static func refreshState(forDeviceId deviceId: Int, completion: @escaping () -> Void) {
        fetchState(forDeviceId: deviceId, completion: completion)
    }

    /// Latest eDRX cycle the collar reported, nil until its first network event.
    public static func edrxSeconds(forDeviceId deviceId: Int) -> Double? {
        return deviceStates[deviceId]?.network?.edrx_s
    }

    private static func startStatePolling() {
        guard statePollTimer == nil else { return }

        statePollTimer = Timer.scheduledTimer(withTimeInterval: statePollInterval, repeats: true) { timer in
            guard !pingsInFlight.isEmpty else {
                timer.invalidate()
                statePollTimer = nil
                return
            }
            let stuckPingDeviceIds = pingsInFlight.filter { deviceId, sentAt in
                guard let edrxSeconds = edrxSeconds(forDeviceId: deviceId) else { return false }
                return Date().timeIntervalSince(sentAt) > edrxSeconds * STUCK_PING_TIMEOUT_EDRX_CYCLES
            }.keys
            if !stuckPingDeviceIds.isEmpty {
                pingsInFlight = pingsInFlight.filter { !stuckPingDeviceIds.contains($0.key) }
            }
            pingsInFlight.keys.forEach { fetchState(forDeviceId: $0) }
        }
    }

    private static func fetchState(forDeviceId deviceId: Int, completion: (() -> Void)? = nil) {
        guard deviceId != 0 else { return } // local debug devices have no server state

        DeviceStatusAPIManager.shared.fetchDeviceState(deviceId: deviceId) { result in
            defer { completion?() }
            switch result {
            case .success(let state):
                deviceStates[deviceId] = state

                // A command result newer than the ping answers it; "sent" is
                // device-commands logging the send, not the collar answering.
                if let sentAt = pingsInFlight[deviceId],
                   let command = state.command, command.status != "sent",
                   command.receivedAt >= sentAt {
                    pingsInFlight[deviceId] = nil
                }
            case .failure(let error):
                Logger(subsystem: "Models", category: String(describing: SharedData.self))
                    .error("Could not fetch device state for \(deviceId): \(error)")
            }
        }
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
                    SharedData.pingsInFlight[newPosition.deviceId] = nil
                }
            }
        } catch {
            logger.error("Error decoding JSON: \(error)")
        }

    }
}
