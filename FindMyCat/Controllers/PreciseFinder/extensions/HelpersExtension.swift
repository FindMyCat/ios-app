//
//  PreciseFinderViewControllerHelpersExtension.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/7/23.
//

import Foundation
import NearbyInteraction
import UIKit

// MARK: - Helpers.
extension PreciseFinderViewContoller {

    internal func connectToAccessory(_ deviceID: Int) {
         do {
             try BLEDataCommunicationChannel.shared.connectPeripheral(deviceID)
         } catch {
             logger.error("Failed to connect to accessory: \(error)")
         }
    }

    enum ConnectionError: Error {
        case connectionFailed
    }
    internal func connectToAccessoryUntilSuccess(_ deviceID: Int, maxRetries: Int, retryDelay: TimeInterval) {
        var retries = 0

        func connectWithDelay() {
            do {
                try BLEDataCommunicationChannel.shared.connectPeripheral(deviceID)
            } catch {
                logger.error("Failed to connect to accessory: \(error)")
                retries += 1
                // Retry after delay
                if retries < maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                        connectWithDelay()
                    }
                }
            }
        }

        connectWithDelay()
    }

    internal func disconnectFromAccessory(_ deviceID: Int) {
         do {
             try BLEDataCommunicationChannel.shared.disconnectPeripheral(deviceID)
         } catch {
             logger.error("Failed to disconnect from accessory: \(error)")
         }
     }

    internal func sendDataToAccessory(_ data: Data, _ deviceID: Int) {
         do {
             try BLEDataCommunicationChannel.shared.sendData(data, deviceID)
         } catch {
             logger.error("Failed to send data to accessory: \(error)")
         }
     }

    internal func handleSessionInvalidation(_ deviceID: Int) {
        logger.log("Session invalidated. Restarting.")
        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)

        // Replace the invalidated session with a new one.
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self

        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.initialize.rawValue]), deviceID)
    }

    internal func shouldRetry(_ deviceID: Int) -> Bool {
        // Need to use the dictionary here, to know which device failed and check its connection state
        let preciseFindableDevice = BLEDataCommunicationChannel.shared.getDeviceFromUniqueID(deviceID)

        if preciseFindableDevice?.blePeripheralStatus != statusDiscovered {
            return true
        }

        return false
    }

    internal func deviceIDFromSession(_ session: NISession) -> Int {
        var deviceID = -1

        for (key, value) in referenceDict {
            if value == session {
                deviceID = key
            }
        }

        return deviceID
    }

    internal func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryDiscoveryTokenToNameMap[token] = accessoryName
    }

    internal func handleUserDidNotAllow() {
        // Beginning in iOS 15, persistent access state in Settings.
        logger.error("Nearby Interactions access required. You can change access for NIAccessory in Settings.")

        // Create an alert to request the user go to Settings.
        let accessAlert = UIAlertController(title: "Access Required",
                                            message: """
                                            NIAccessory requires access to Nearby Interactions for this sample app.
                                            Use this string to explain to users which functionality will be enabled if they change
                                            Nearby Interactions access in Settings.
                                            """,
                                            preferredStyle: .alert)
        accessAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        accessAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {_ in
            // Navigate the user to the app's settings.
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }))

        // Preset the access alert.
        present(accessAlert, animated: true, completion: nil)
    }
}
