//
//  PreciseFinderViewControllerSessionDelegates.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/7/23.
//

import Foundation
import NearbyInteraction
import ARKit

// MARK: - `ARSessionDelegate`.
extension PreciseFinderViewContoller: ARSessionDelegate {
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return false
    }
}

// MARK: - `NISessionDelegate`.
extension PreciseFinderViewContoller: NISessionDelegate {

    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        guard object.discoveryToken == accessoryConfig?.accessoryDiscoveryToken else { return }

        // Prepare to send a message to the accessory.
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)

        let str = msg.map { String(format: "0x%02x, ", $0) }.joined()
        logger.info("Sending shareable configuration bytes: \(str)")

        // Send the message to the correspondent accessory.
        sendDataToAccessory(msg, deviceIDFromSession(session))
        print("Sent shareable configuration data.")
    }

    func session(_ session: NISession, didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence, for object: NINearbyObject?) {
        print("Convergence Status:\(convergence.status)")
        // TODO: To Refactor delete to only know converged or not

        guard let accessory = object else { return}

        switch convergence.status {
        case .converged:
            print("Horizontal Angle: \(accessory.horizontalAngle)")
            print("verticalDirectionEstimate: \(accessory.verticalDirectionEstimate)")
            print("Converged")
            NIAlgorithmHasConverged = true
        case .notConverged([NIAlgorithmConvergenceStatus.Reason.insufficientLighting]):
            print("More light required")
            NIAlgorithmHasConverged = false
        default:
            print("Try moving in a different direction...")
        }

    }
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        guard let distance  = accessory.distance else { return }

        let deviceID = deviceIDFromSession(session)
        // print(NISession.deviceCapabilities)

        if let updatedDevice = DataCommunicationChannel.shared.getDeviceFromUniqueID(deviceID) {
            // set updated values
            updatedDevice.uwbLocation?.distance = distance

            if let direction = accessory.direction {
                updatedDevice.uwbLocation?.direction = direction
                updatedDevice.uwbLocation?.noUpdate  = false
            }
            // TODO: For IPhone 14 only
            else if NIAlgorithmHasConverged {
                guard let horizontalAngle = accessory.horizontalAngle else {return}
                updatedDevice.uwbLocation?.direction = getDirectionFromHorizontalAngle(rad: horizontalAngle)
                updatedDevice.uwbLocation?.elevation = accessory.verticalDirectionEstimate.rawValue
                updatedDevice.uwbLocation?.noUpdate  = false
            } else {
                updatedDevice.uwbLocation?.noUpdate  = true
            }

            updatedDevice.blePeripheralStatus = statusRanging
        }

        updateDeviceData(deviceID)

    }

    func updateDeviceData(_ deviceID: Int) {

        let preciseFindableDevice = DataCommunicationChannel.shared.getDeviceFromUniqueID(deviceID)
        if preciseFindableDevice == nil { return }

        // Get updated location values
        let distance  = preciseFindableDevice?.uwbLocation?.distance
        let azimuthCheck = azimuth((preciseFindableDevice?.uwbLocation?.direction)!)

        // Check if azimuth check calcul is a number (ie: not infinite)
        if azimuthCheck.isNaN {
            return
        }

        var azimuth = 0
        if NISession.deviceCapabilities.supportsDirectionMeasurement {
            azimuth =  Int( 90 * (Double(azimuthCheck)))
        } else {
            azimuth = Int(rad2deg(Double(azimuthCheck)))
        }

        distanceLabel.text = String(format: "%.1f ft", convertMetersToFeet(meters: distance!))

        // Update  arrow
        let radians: CGFloat = CGFloat(azimuth) * (.pi / 180)
        UIView.animate(withDuration: 0.3) {
            self.arrowImgView.transform = CGAffineTransform(rotationAngle: radians)
        }

    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {

        // Retry the session only if the peer timed out.
        guard reason == .timeout else { return }
        print("Session timed out")

        // The session runs with one accessory.
        guard let accessory = nearbyObjects.first else { return }

        // Clear the app's accessory state.
        accessoryDiscoveryTokenToNameMap.removeValue(forKey: accessory.discoveryToken)

        // Get the deviceID associated to the NISession
        let deviceID = deviceIDFromSession(session)

        // Consult helper function to decide whether or not to retry.
        if shouldRetry(deviceID) {
            sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)
            sendDataToAccessory(Data([MessageId.initialize.rawValue]), deviceID)
        }
    }

    func sessionWasSuspended(_ session: NISession) {
        print("Session was suspended.")
        let msg = Data([MessageId.stop.rawValue])

        sendDataToAccessory(msg, deviceIDFromSession(session))
    }

    func sessionSuspensionEnded(_ session: NISession) {
        print("Session suspension ended.")
        // When suspension ends, restart the configuration procedure with the accessory.
        let msg = Data([MessageId.initialize.rawValue])

        sendDataToAccessory(msg, deviceIDFromSession(session))
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        let deviceID = deviceIDFromSession(session)

        switch error {
        case NIError.invalidConfiguration:
            // Debug the accessory data to ensure an expected format.
            print("The accessory configuration data is invalid. Please debug it and try again.")
        case NIError.userDidNotAllow:
            handleUserDidNotAllow()
        case NIError.invalidConfiguration:
            print("Check the ARConfiguration used to run the ARSession")
        default:
            print("invalidated: \(error)")
            handleSessionInvalidation(deviceID)
        }
    }
}
