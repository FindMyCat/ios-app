//
//  PreciseFinderViewControllerDataCommunicationExtension.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/7/23.
//

import Foundation
import NearbyInteraction

// MARK: - Data communication extension for Precise View finder.
extension PreciseFinderViewContoller {
    // MARK: - Setup Data channel
    internal func configureDataChannel() {
        DataCommunicationChannel.shared.accessoryDataHandler = accessorySharedData

        // Prepare the data communication channel.
        DataCommunicationChannel.shared.accessoryDiscoveryHandler = accessoryInclude
        DataCommunicationChannel.shared.accessoryTimeoutHandler = accessoryRemove
        DataCommunicationChannel.shared.accessoryConnectedHandler = accessoryConnected
        DataCommunicationChannel.shared.accessoryDisconnectedHandler = accessoryDisconnected
        DataCommunicationChannel.shared.accessoryDataHandler = accessorySharedData
        DataCommunicationChannel.shared.start()

    }

    internal func deinitDataCommunicationChannel() {
        DataCommunicationChannel.shared.accessoryDataHandler = nil

        // Prepare the data communication channel.
        DataCommunicationChannel.shared.accessoryDiscoveryHandler = nil
        DataCommunicationChannel.shared.accessoryTimeoutHandler = nil
        DataCommunicationChannel.shared.accessoryConnectedHandler = nil
        DataCommunicationChannel.shared.accessoryDisconnectedHandler = nil
        DataCommunicationChannel.shared.accessoryDataHandler = nil
        DataCommunicationChannel.shared.stop()
    }

    // MARK: - Data channel event handlers
    internal func accessoryInclude(index: Int) {

        guard let device = DataCommunicationChannel.shared.getDeviceFromUniqueID(deviceUniqueBLEId) else {
            return
        }

        if device.bleUniqueID == deviceUniqueBLEId {
            // Connect to the accessory
            if device.blePeripheralStatus == statusDiscovered {
                logger.info("Connecting to Accessory")
                connectToAccessory(device.bleUniqueID)
            } else {
                return
            }
        }
    }

    internal func accessoryRemove(deviceID: Int) {
        // TODO: accessoryRemove
    }

    internal func accessoryUpdate() {
        // TODO: accessoryUpdate
    }

    internal func accessoryConnected(deviceID: Int) {
        // Create a NISession for the new device
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self
        referenceDict[deviceID]?.setARSession(arView.session)

        let msg = Data([MessageId.initialize.rawValue])

        sendDataToAccessory(msg, deviceID)
    }

    internal func accessoryDisconnected(deviceID: Int) {

        referenceDict[deviceID]?.invalidate()
        // Remove the NI Session and Location values related to the device ID
        referenceDict.removeValue(forKey: deviceID)

        accessoryUpdate()
    }

    internal func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
        // The accessory begins each message with an identifier byte.
        // Ensure the message length is within a valid range.
        if data.count < 1 {
            print("Accessory shared data length was less than 1.")
            return
        }

        // Assign the first byte which is the message identifier.
        guard let messageId = MessageId(rawValue: data.first!) else {
            fatalError("\(data.first!) is not a valid MessageId.")
        }

        // Handle the data portion of the message based on the message identifier.
        switch messageId {
        case .accessoryConfigurationData:
            // Access the message data by skipping the message identifier.
            assert(data.count > 1)
            let message = data.advanced(by: 1)
            setupAccessory(message, name: accessoryName, deviceID: deviceID)
        case .accessoryUwbDidStart:
            handleAccessoryUwbDidStart(deviceID)
        case .accessoryUwbDidStop:
            handleAccessoryUwbDidStop(deviceID)
        case .configureAndStart:
            fatalError("Accessory should not send 'configureAndStart'.")
        case .initialize:
            fatalError("Accessory should not send 'initialize'.")
        case .stop:
            fatalError("Accessory should not send 'stop'.")
        // User defined/notification messages
        case .getReserved:
            print("Get not implemented in this version")
        case .setReserved:
            print("Set not implemented in this version")
        case .iOSNotify:
            print("Notification not implemented in this version")
        }
    }

    // MARK: - Accessory messages handling
    internal func setupAccessory(_ configData: Data, name: String, deviceID: Int) {
        print("Received configuration data from '\(name)'. Running session.")
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            configuration?.isCameraAssistanceEnabled = true
        } catch {
            // Stop and display the issue because the incoming data is invalid.
            // In your app, debug the accessory data to ensure an expected
            // format.
            print("Failed to create NINearbyAccessoryConfiguration for '\(name)'. Error: \(error)")
            return
        }

        // Cache the token to correlate updates with this accessory.
        cacheToken(configuration!.accessoryDiscoveryToken, accessoryName: name)

        referenceDict[deviceID]?.run(configuration!)
        print("Accessory Session configured.")

    }

    internal func handleAccessoryUwbDidStart(_ deviceID: Int) {
        print("Accessory Session started.")

        // Update the device Status
        if let startedDevice = DataCommunicationChannel.shared.getDeviceFromUniqueID(deviceID) {
            startedDevice.blePeripheralStatus = statusRanging
        }

        // Enables Location assets when Qorvo device starts ranging
        // TODO: Check if this is still necessary
//        enableLocation(true)
    }

    internal func handleAccessoryUwbDidStop(_ deviceID: Int) {
        print("Accessory Session stopped.")

        // Disconnect from device
        disconnectFromAccessory(deviceID)
    }

}
