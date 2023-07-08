//
//  PreciseViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/5/23.
//

import Foundation
import UIKit
import AVFoundation
import ARKit
import RealityKit
import NearbyInteraction
import os.log

class PreciseFinderViewContoller: UIViewController {

    // MARK: - Device to connect to
    var deviceDisplayName: String
    var deviceUniqueBLEId: Int

    // MARK: - Simple views to show information
    private let arrowImgView = UIImageView(image: UIImage(systemName: "arrow.up"))

    private let deviceNameLabel = UILabel()
    private let distanceLabel = UILabel()
    private let cancelButton = UIButton()
    private let soundButton = UIButton()
    private let circle = UIView()
    let viewLayerColor = UIColor.white

    // MARK: AR camera layer for blurring
    private var arView: ARSCNView!
    let arConfig = ARWorldTrackingConfiguration()

    // MARK: UWB
    var dataChannel = DataCommunicationChannel()
    // Dictionary to associate each NI Session to the qorvoDevice using the uniqueID
    var referenceDict = [Int: NISession]()
    // A mapping from a discovery token to a name.
    var accessoryMap = [NIDiscoveryToken: String]()
    var configuration: NINearbyAccessoryConfiguration?
    var isConverged = false

    // Extras
    let logger = os.Logger(subsystem: "com.chitlangesahas.FindMyCat", category: "PreciseViewContoller")

    // MARK: - Initializers

    init(deviceDisplayName: String, deviceUniqueBLEId: Int) {
        self.deviceDisplayName = deviceDisplayName
        self.deviceUniqueBLEId = deviceUniqueBLEId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycles
    override func viewDidLoad() {
        view.backgroundColor = .white
        setupSubviews()

        configureDataChannel()
    }

    // MARK: - Setup subviews

    private func setupSubviews() {
        setupCameraBlurLayer()
        setupArrowImage()
        setupDeviceName()
        setupControlButtons()
        setupDistanceLabel()
        setupCircleAroundArrow()
    }

    func setupArrowImage() {
        view.addSubview(arrowImgView)

        arrowImgView.tintColor = viewLayerColor

        arrowImgView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = arrowImgView.widthAnchor.constraint(equalToConstant: 200)
        let heightConstraint = arrowImgView.heightAnchor.constraint(equalToConstant: 200)

        NSLayoutConstraint.activate([
            arrowImgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowImgView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heightConstraint,
            widthConstraint
        ])
    }

    func setupCameraBlurLayer() {

        arView = ARSCNView(frame: view.bounds)
        view.addSubview(arView)

        // Set/start AR Session to provide camera assistance to new NI Sessions
        arConfig.worldAlignment = .gravity
        arConfig.isCollaborationEnabled = false
        arConfig.userFaceTrackingEnabled = false
        arConfig.initialWorldMap = nil
        arView.session = ARSession()
        arView.session.delegate = self
        arView.session.run(arConfig)

        // Apply blur effect to the background view
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        self.view.addSubview(blurEffectView)
    }

    func setupDeviceName() {
        view.addSubview(deviceNameLabel)

        deviceNameLabel.text = deviceDisplayName
        deviceNameLabel.font = UIFont.boldSystemFont(ofSize: 40)
        deviceNameLabel.textColor = viewLayerColor

        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deviceNameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            deviceNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30)
        ])
    }

    func setupControlButtons() {
        setupCancelButton()
        setupSoundButton()
    }

    func setupCancelButton() {
        view.addSubview(cancelButton)

        cancelButton.configuration = UIButton.Configuration.tinted()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.configuration?.cornerStyle = .capsule
        cancelButton.configuration?.buttonSize = .large

        cancelButton.tintColor = viewLayerColor
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30)
        ])

        // Add a target to the cancelButton
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)

    }

    @objc private func cancelButtonPressed() {
        // cleanup -- stop the data channel and disconnect from Device.
        dataChannel.stop()
        disconnectFromAccessory(deviceUniqueBLEId)
        dismiss(animated: true, completion: nil)
    }

    func setupSoundButton() {
        view.addSubview(soundButton)

        soundButton.configuration = UIButton.Configuration.tinted()
        soundButton.setTitle("Sound", for: .normal)
        soundButton.configuration?.cornerStyle = .capsule
        soundButton.configuration?.buttonSize = .large

        soundButton.tintColor = viewLayerColor
        soundButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            soundButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            soundButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }

    func setupDistanceLabel() {
        view.addSubview(distanceLabel)

//        distanceLabel.text = "10 ft"
        distanceLabel.font = UIFont.boldSystemFont(ofSize: 50)
        distanceLabel.textColor = viewLayerColor

        distanceLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            distanceLabel.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -20),
            distanceLabel.leadingAnchor.constraint(equalTo: cancelButton.leadingAnchor)
        ])

    }

    func setupCircleAroundArrow() {
        let circleSize = CGFloat(300)
        circle.layer.cornerRadius = circleSize / 2
        circle.layer.borderWidth = 4.0
        circle.layer.borderColor = viewLayerColor.cgColor
        circle.alpha = 0.4

        view.addSubview(circle)

        circle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: circleSize),
            circle.heightAnchor.constraint(equalToConstant: circleSize)
        ])
    }

    // MARK: - Setup Data channel
    private func configureDataChannel() {
        dataChannel.accessoryDataHandler = accessorySharedData

        // Prepare the data communication channel.
        dataChannel.accessoryDiscoveryHandler = accessoryInclude
        dataChannel.accessoryTimeoutHandler = accessoryRemove
        dataChannel.accessoryConnectedHandler = accessoryConnected
        dataChannel.accessoryDisconnectedHandler = accessoryDisconnected
        dataChannel.accessoryDataHandler = accessorySharedData
        dataChannel.start()

    }
    // MARK: - Data channel methods
    func accessoryInclude(index: Int) {

        guard let device = dataChannel.getDeviceFromUniqueID(deviceUniqueBLEId) else {
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

    func accessoryRemove(deviceID: Int) {

    }

    func accessoryUpdate() {
        // TODO: accessoryUpdate
    }

    func accessoryConnected(deviceID: Int) {
        // Create a NISession for the new device
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self
        referenceDict[deviceID]?.setARSession(arView.session)

        let msg = Data([MessageId.initialize.rawValue])

        sendDataToAccessory(msg, deviceID)
    }

    func accessoryDisconnected(deviceID: Int) {

        referenceDict[deviceID]?.invalidate()
        // Remove the NI Session and Location values related to the device ID
        referenceDict.removeValue(forKey: deviceID)

        accessoryUpdate()
    }

    func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
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
    func setupAccessory(_ configData: Data, name: String, deviceID: Int) {
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

    func handleAccessoryUwbDidStart(_ deviceID: Int) {
        print("Accessory Session started.")

        // Update the device Status
        if let startedDevice = dataChannel.getDeviceFromUniqueID(deviceID) {
            startedDevice.blePeripheralStatus = statusRanging
        }

        // Enables Location assets when Qorvo device starts ranging
        // TODO: Check if this is still necessary
//        enableLocation(true)
    }

    func handleAccessoryUwbDidStop(_ deviceID: Int) {
        print("Accessory Session stopped.")

        // Disconnect from device
        disconnectFromAccessory(deviceID)
    }

}

// MARK: - `ARSessionDelegate`.
extension PreciseFinderViewContoller: ARSessionDelegate {
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return false
    }
}

// MARK: - `NISessionDelegate`.
extension PreciseFinderViewContoller: NISessionDelegate {

    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        guard object.discoveryToken == configuration?.accessoryDiscoveryToken else { return }

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
            isConverged = true
        case .notConverged([NIAlgorithmConvergenceStatus.Reason.insufficientLighting]):
            print("More light required")
            isConverged = false
        default:
            print("Try moving in a different direction...")
        }

    }
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        guard let distance  = accessory.distance else { return }

        let deviceID = deviceIDFromSession(session)
        // print(NISession.deviceCapabilities)

        if let updatedDevice = dataChannel.getDeviceFromUniqueID(deviceID) {
            // set updated values
            updatedDevice.uwbLocation?.distance = distance

            if let direction = accessory.direction {
                updatedDevice.uwbLocation?.direction = direction
                updatedDevice.uwbLocation?.noUpdate  = false
            }
            // TODO: For IPhone 14 only
            else if isConverged {
                guard let horizontalAngle = accessory.horizontalAngle else {return}
                updatedDevice.uwbLocation?.direction = getDirectionFromHorizontalAngle(rad: horizontalAngle)
                updatedDevice.uwbLocation?.elevation = accessory.verticalDirectionEstimate.rawValue
                updatedDevice.uwbLocation?.noUpdate  = false
            } else {
                updatedDevice.uwbLocation?.noUpdate  = true
            }

            updatedDevice.blePeripheralStatus = statusRanging
        }

//        updateLocationFields(deviceID)
        updateDeviceData(deviceID)

    }

    func updateDeviceData(_ deviceID: Int) {

        let qorvoDevice = dataChannel.getDeviceFromUniqueID(deviceID)
        if qorvoDevice == nil { return }

        // Get updated location values
        let distance  = qorvoDevice?.uwbLocation?.distance
        let azimuthCheck = azimuth((qorvoDevice?.uwbLocation?.direction)!)

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

        print(convertMetersToFeet(meters: distance!), radians)

    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {

        // Retry the session only if the peer timed out.
        guard reason == .timeout else { return }
        print("Session timed out")

        // The session runs with one accessory.
        guard let accessory = nearbyObjects.first else { return }

        // Clear the app's accessory state.
        accessoryMap.removeValue(forKey: accessory.discoveryToken)

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

// MARK: - Helpers.
extension PreciseFinderViewContoller {

    func connectToAccessory(_ deviceID: Int) {
         do {
             try dataChannel.connectPeripheral(deviceID)
         } catch {
             print("Failed to connect to accessory: \(error)")
         }
    }

    func disconnectFromAccessory(_ deviceID: Int) {
         do {
             try dataChannel.disconnectPeripheral(deviceID)
         } catch {
             print("Failed to disconnect from accessory: \(error)")
         }
     }

    func sendDataToAccessory(_ data: Data, _ deviceID: Int) {
         do {
             try dataChannel.sendData(data, deviceID)
         } catch {
             print("Failed to send data to accessory: \(error)")
         }
     }

    func handleSessionInvalidation(_ deviceID: Int) {
        print("Session invalidated. Restarting.")
        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)

        // Replace the invalidated session with a new one.
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self

        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.initialize.rawValue]), deviceID)
    }

    func shouldRetry(_ deviceID: Int) -> Bool {
        // Need to use the dictionary here, to know which device failed and check its connection state
        let qorvoDevice = dataChannel.getDeviceFromUniqueID(deviceID)

        if qorvoDevice?.blePeripheralStatus != statusDiscovered {
            return true
        }

        return false
    }

    func deviceIDFromSession(_ session: NISession) -> Int {
        var deviceID = -1

        for (key, value) in referenceDict {
            if value == session {
                deviceID = key
            }
        }

        return deviceID
    }

    func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
    }

    func handleUserDidNotAllow() {
        // Beginning in iOS 15, persistent access state in Settings.
        print("Nearby Interactions access required. You can change access for NIAccessory in Settings.")

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
