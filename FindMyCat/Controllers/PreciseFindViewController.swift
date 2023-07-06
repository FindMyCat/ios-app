/*
 * @file      QorvoDemoViewController.swift
 *
 * @brief     Main Application View Controller.
 *
 * @author    Decawave Applications
 *
 * @attention Copyright (c) 2021 - 2022, Qorvo US, Inc.
 * All rights reserved
 * Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice, this
 *  list of conditions, and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *  this list of conditions and the following disclaimer in the documentation
 *  and/or other materials provided with the distribution.
 * 3. You may only use this software, with or without any modification, with an
 *  integrated circuit developed by Qorvo US, Inc. or any of its affiliates
 *  (collectively, "Qorvo"), or any module that contains such integrated circuit.
 * 4. You may not reverse engineer, disassemble, decompile, decode, adapt, or
 *  otherwise attempt to derive or gain access to the source code to any software
 *  distributed under this license in binary or object code form, in whole or in
 *  part.
 * 5. You may not use any Qorvo name, trademarks, service marks, trade dress,
 *  logos, trade names, or other symbols or insignia identifying the source of
 *  Qorvo's products or services, or the names of any of Qorvo's developers to
 *  endorse or promote products derived from this software without specific prior
 *  written permission from Qorvo US, Inc. You must not call products derived from
 *  this software "Qorvo", you must not have "Qorvo" appear in their name, without
 *  the prior permission from Qorvo US, Inc.
 * 6. Qorvo may publish revised or new version of this license from time to time.
 *  No one other than Qorvo US, Inc. has the right to modify the terms applicable
 *  to the software provided under this license.
 * THIS SOFTWARE IS PROVIDED BY QORVO US, INC. "AS IS" AND ANY EXPRESS OR IMPLIED
 *  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. NEITHER
 *  QORVO, NOR ANY PERSON ASSOCIATED WITH QORVO MAKES ANY WARRANTY OR
 *  REPRESENTATION WITH RESPECT TO THE COMPLETENESS, SECURITY, RELIABILITY, OR
 *  ACCURACY OF THE SOFTWARE, THAT IT IS ERROR FREE OR THAT ANY DEFECTS WILL BE
 *  CORRECTED, OR THAT THE SOFTWARE WILL OTHERWISE MEET YOUR NEEDS OR EXPECTATIONS.
 * IN NO EVENT SHALL QORVO OR ANYBODY ASSOCIATED WITH QORVO BE LIABLE FOR ANY
 *  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

import UIKit
import NearbyInteraction
import ARKit
import RealityKit
import CoreHaptics
import os.log

// An example messaging protocol for communications between the app and the
// accessory. In your app, modify or extend this enumeration to your app's
// user experience and conform the accessory accordingly.
enum MessageId: UInt8 {
    // Messages from the accessory.
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3

    // Messages to the accessory.
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC

    // User defined/notification messages
    case getReserved = 0x20
    case setReserved = 0x21

    case iOSNotify = 0x2F
}

// Base struct for the feedback array implementing three different feedback levels
struct FeedbackLvl {
    var hummDuration: TimeInterval
    var timerIndexRef: Int
}

protocol ArrowProtocol {
    func switchArrowImgView()
}

class AccessoryDemoViewController: UIViewController, ARSCNViewDelegate, ArrowProtocol,
                                   UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var elevationLabel: UILabel!

    var accessoriesTable: UITableView!

    // Arrow View
    var arrowImgView: UIImageView!

    let qorvoGray = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.00)
    let qorvoBlue = UIColor(red: 0.00, green: 159/255, blue: 1.00, alpha: 1.00)
    let qorvoRed  = UIColor(red: 1.00, green: 123/255, blue: 123/255, alpha: 1.00)

    var dataChannel = DataCommunicationChannel()
    var configuration: NINearbyAccessoryConfiguration?
    var selectedAccessory = -1
    var selectExpand = true
    var isConverged = false

    // Used to animate scanning images
    var imageScanning      = [UIImage]()
    var imageScanningSmall = [UIImage]()
    // Dictionary to associate each NI Session to the qorvoDevice using the uniqueID
    var referenceDict = [Int: NISession]()
    // A mapping from a discovery token to a name.
    var accessoryMap = [NIDiscoveryToken: String]()

    // Auxiliary variables for feedback
    var engine: CHHapticEngine?
    var feedbackDisabled: Bool = true
    var feedbackLevel: Int = 0
    var feedbackLevelOld: Int = 0
    var feedbackPar: [FeedbackLvl] = [FeedbackLvl(hummDuration: 1.0, timerIndexRef: 8),
                                      FeedbackLvl(hummDuration: 0.5, timerIndexRef: 4),
                                      FeedbackLvl(hummDuration: 0.1, timerIndexRef: 1)]
    // Auxiliary variables to handle the feedback Timer
    var timerIndex: Int = 0
    // Auxiliary variables to handle the 3D arrow
    var curAzimuth: Int = 0
    var curElevation: Int = 0
    var curSpin: Int = 0

    let logger = os.Logger(subsystem: "com.example.apple-samplecode.NINearbyAccessorySample", category: "AccessoryDemoViewController")

    let btnDisabled = "Disabled"
    let btnConnect = "Connect"
    let btnDisconnect = "Disconnect"
    let devNotConnected = "NO ACCESSORY CONNECTED"

    override func viewDidLoad() {
        super.viewDidLoad()

        dataChannel.accessoryDataHandler = accessorySharedData

        // To update UI regarding NISession Device Direction Capabilities
        checkDirectionIsEnable()

        startArrowImgView()

        // Prepare the data communication channel.
        dataChannel.accessoryDiscoveryHandler = accessoryInclude
        dataChannel.accessoryTimeoutHandler = accessoryRemove
        dataChannel.accessoryConnectedHandler = accessoryConnected
        dataChannel.accessoryDisconnectedHandler = accessoryDisconnected
        dataChannel.accessoryDataHandler = accessorySharedData
        dataChannel.start()

        // Initialises the Timer used for Haptic and Sound feedbacks
        _ = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)

        // Initialises table to stack devices from qorvoDevices
        accessoriesTable = UITableView()
        accessoriesTable.delegate   = self
        accessoriesTable.dataSource = self

        infoLabelUpdate(with: "Scanning for accessories")

        // Add gesture recognition to "Devices near you" UIView
        let upSwipe   = UISwipeGestureRecognizer(target: self, action: #selector(swipeHandler))
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeHandler))

        upSwipe.direction   = .up
        downSwipe.direction = .down

        arrowImgView = UIImageView(image: UIImage(systemName: "arrow.up.circle.fill"))
        arrowImgView.backgroundColor = .red

        view.addSubview(arrowImgView)

        NSLayoutConstraint.activate([
            arrowImgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowImgView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        view.backgroundColor = .yellow

        logger.log("whoo")

    }

    func checkDirectionIsEnable() {
        // if NISession device direction capabilities is disabled
        if !appSettings.isDirectionEnable {

        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
            .lightContent
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SettingsViewController {
            destination.delegate = self
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return qorvoDevices.count
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let disconnect = UIContextualAction(style: .normal, title: "") { [self] (_, _, completion) in
            // Send the disconnection message to the device
            let cell = accessoriesTable.cellForRow(at: indexPath) as! DeviceTableViewCell
            let deviceID = cell.uniqueID
            let qorvoDevice = dataChannel.getDeviceFromUniqueID(deviceID)

            if qorvoDevice?.blePeripheralStatus != statusDiscovered {
                sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)
            }
            completion(true)
        }
        // Set the Contextual action parameters
        disconnect.image = UIImage(named: "trash_bin")
        disconnect.backgroundColor = qorvoRed

        let swipeActions = UISwipeActionsConfiguration(actions: [disconnect])
        swipeActions.performsFirstActionWithFullSwipe = false

        return swipeActions
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = accessoriesTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DeviceTableViewCell

        let qorvoDevice = qorvoDevices[indexPath.row]

        cell.uniqueID = (qorvoDevice?.bleUniqueID)!

        // Initialize the new cell assets
        cell.tag = indexPath.row
        cell.accessoryButton.tag = indexPath.row
        cell.accessoryButton.setTitle(qorvoDevice?.blePeripheralName, for: .normal)
        cell.accessoryButton.addTarget(self,
                                       action: #selector(buttonSelect),
                                       for: .touchUpInside)
        cell.actionButton.tag = indexPath.row
        cell.actionButton.addTarget(self,
                                    action: #selector(buttonAction),
                                    for: .touchUpInside)
        cell.scanning.animationImages = imageScanningSmall
        cell.scanning.animationDuration = 1

        logger.info("New device included at row \(indexPath.row)")

        return cell
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        hideDetails(true)
    }

    @objc func swipeHandler(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            if gestureRecognizer.direction == .up {
                hideDetails(true)
            }
            if gestureRecognizer.direction == .down {
                hideDetails(false)
            }
        }
    }

    func hideDetails(_ hide: Bool) {
        UIView.animate(withDuration: 0.4) {
            self.accessoriesTable.isHidden = !hide
        }
    }

    @IBAction func buttonAction(_ sender: UIButton) {

        if let qorvoDevice = qorvoDevices[sender.tag] {
            let deviceID = qorvoDevice.bleUniqueID

            // Connect to the accessory
            if qorvoDevice.blePeripheralStatus == statusDiscovered {
                infoLabelUpdate(with: "Connecting to Accessory")
                connectToAccessory(deviceID)
            } else {
                return
            }

            // Edit cell for this sender
            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.tag == sender.tag {
                    cell.selectAsset(.scanning)
                }
            }

            logger.info("Action Button pressed for device \(deviceID)")
        }
    }

    @IBAction func buttonSelect(_ sender: UIButton) {

        if let qorvoDevice = qorvoDevices[sender.tag] {
            let deviceID = qorvoDevice.bleUniqueID

            selectDevice(deviceID)
            logger.info("Select Button pressed for device \(deviceID)")
        }
    }

    @objc func timerHandler() {
        // Feedback only enabled if the Qorvo device started ranging
        if !appSettings.audioHapticEnabled! || feedbackDisabled {
            return
        }

        if selectedAccessory == -1 {
            return
        }

        let qorvoDevice = dataChannel.getDeviceFromUniqueID(selectedAccessory)

        if qorvoDevice?.blePeripheralStatus != statusRanging {
            return
        }

        // As the timer is fast timerIndex and timerIndexRef provides a
        // pre-scaler to achieve different patterns
        if  timerIndex != feedbackPar[feedbackLevel].timerIndexRef {
            timerIndex += 1
            return
        }

        timerIndex = 0

        // Handles Sound, if enabled
        let systemSoundID: SystemSoundID = 1052
        AudioServicesPlaySystemSound(systemSoundID)

        // Handles Haptic, if enabled
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        let humm = CHHapticEvent(eventType: .hapticContinuous,
                                 parameters: [],
                                 relativeTime: 0,
                                 duration: feedbackPar[feedbackLevel].hummDuration)
        events.append(humm)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            logger.info("Failed to play pattern: \(error.localizedDescription).")
        }
    }

    func setFeedbackLvl(distance: Float) {
        // Select feedback Level according to the distance
        if distance > 4.0 {
            feedbackLevel = 0
        } else if distance > 2.0 {
            feedbackLevel = 1
        } else {
            feedbackLevel = 2
        }

        // If level changes, apply immediately
        if feedbackLevel != feedbackLevelOld {
            timerIndex = 0
            feedbackLevelOld = feedbackLevel
        }
    }

    func selectDevice(_ deviceID: Int) {
        // If an accessory was selected, clear highlight
        if selectedAccessory != -1 {

            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.uniqueID == selectedAccessory {
                    cell.accessoryButton.backgroundColor = .white
                }
            }
        }

        // Set the new selected accessory
        selectedAccessory = deviceID

        // If no accessory is selected, reset location fields
        if deviceID == -1 {
            clearLocationFields()

            // Disables Location assets when Qorvo device is not ranging
            enableLocation(false)

            deviceLabel.text = "NOT CONNECTED"

            return
        }

        // If a new accessory is selected initialise location
        if let chosenDevice = dataChannel.getDeviceFromUniqueID(deviceID) {

            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.uniqueID == deviceID {
                    cell.accessoryButton.backgroundColor = qorvoGray
                }
            }

            logger.info("Selecting device \(deviceID)")
            deviceLabel.text = chosenDevice.blePeripheralName

            if chosenDevice.blePeripheralStatus == statusDiscovered {
                // Clear location values
                clearLocationFields()
                // Disables Location assets when Qorvo device is not ranging
                enableLocation(false)
            } else {
                // Update location values
                updateLocationFields(deviceID)
                // Enables Location assets when Qorvo device is ranging
                enableLocation(true)
                // Show location fields
                hideDetails(false)
            }
        }
    }

    // MARK: - Arrow methods
    func startArrowImgView() {
        // Set scene settings
        initArrowPosition()
        switchArrowImgView()
    }

    func switchArrowImgView() {
        if appSettings.arrowEnabled! {
//            arrowImgView.autoenablesDefaultLighting = true
        } else {
//            arrowImgView.autoenablesDefaultLighting = false
        }
    }

    func initArrowPosition() {
        let degree = 1.0 * Float.pi / 180.0

//        arrowImgView.scene?.rootNode.eulerAngles.x = -90 * degree
//        arrowImgView.scene?.rootNode.eulerAngles.y = 0
//        arrowImgView.scene?.rootNode.eulerAngles.z = 0

        curAzimuth = 0
        curElevation = 0
        curSpin = 0
    }

    func setArrowAngle(newElevation: Int, newAzimuth: Int) {
        let oneDegree = 1.0 * Float.pi / 180.0
        var deltaX, deltaY, deltaZ: Int

        if appSettings.arrowEnabled! {
            deltaX = newElevation - curElevation
            deltaY = newAzimuth - curAzimuth
            deltaZ = 0 - curSpin

            curElevation = newElevation
            curAzimuth = newAzimuth
            curSpin = 0
        } else {
            deltaX = 90 - curElevation
            deltaY = 0 - curAzimuth
            deltaZ = newAzimuth - curSpin

            curElevation = 90
            curAzimuth = 0
            curSpin = newAzimuth
        }

//        arrowImgView.scene?.rootNode.eulerAngles.x += Float(deltaX) * oneDegree
//        arrowImgView.scene?.rootNode.eulerAngles.y -= Float(deltaY) * oneDegree
//        arrowImgView.scene?.rootNode.eulerAngles.z -= Float(deltaZ) * oneDegree
    }

    // MARK: - Data channel methods
    func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
        // The accessory begins each message with an identifier byte.
        // Ensure the message length is within a valid range.
        if data.count < 1 {
            infoLabelUpdate(with: "Accessory shared data length was less than 1.")
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

    func accessoryInclude(index: Int) {
        accessoriesTable.beginUpdates()
        accessoriesTable.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        accessoriesTable.endUpdates()
    }

    func accessoryRemove(deviceID: Int) {
        var index = 0

        for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
            if cell.uniqueID == deviceID {
                break
            }
            index += 1
        }

        accessoriesTable.beginUpdates()
        accessoriesTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        accessoriesTable.endUpdates()
    }

    func accessoryUpdate() {
        // Update devices
        qorvoDevices.forEach { (qorvoDevice) in
            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.uniqueID == qorvoDevice?.bleUniqueID {
                    // Update cell based on status
                    if qorvoDevice?.blePeripheralStatus == statusDiscovered {
                        cell.selectAsset(.actionButton)
                    }
                }
            }
        }
    }

    func accessoryConnected(deviceID: Int) {
        // If no device is selected, select the new device
        if selectedAccessory == -1 {
            selectDevice(deviceID)
        }

        // Create a NISession for the new device
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self

        infoLabelUpdate(with: "Requesting configuration data from accessory")
        let msg = Data([MessageId.initialize.rawValue])

        sendDataToAccessory(msg, deviceID)
    }

    func accessoryDisconnected(deviceID: Int) {

        referenceDict[deviceID]?.invalidate()
        // Remove the NI Session and Location values related to the device ID
        referenceDict.removeValue(forKey: deviceID)

        if selectedAccessory == deviceID {
            selectDevice(-1)
        }

        accessoryUpdate()

        // Update device list and take other actions depending on the amount of devices
        let deviceCount = qorvoDevices.count

        if deviceCount == 0 {
            selectDevice(-1)

            infoLabelUpdate(with: "Accessory disconnected")
        }
    }

    // MARK: - Accessory messages handling
    func setupAccessory(_ configData: Data, name: String, deviceID: Int) {
        infoLabelUpdate(with: "Received configuration data from '\(name)'. Running session.")
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            configuration?.isCameraAssistanceEnabled = true
        } catch {
            // Stop and display the issue because the incoming data is invalid.
            // In your app, debug the accessory data to ensure an expected
            // format.
            infoLabelUpdate(with: "Failed to create NINearbyAccessoryConfiguration for '\(name)'. Error: \(error)")
            return
        }

        // Cache the token to correlate updates with this accessory.
        cacheToken(configuration!.accessoryDiscoveryToken, accessoryName: name)

        referenceDict[deviceID]?.run(configuration!)
        infoLabelUpdate(with: "Accessory Session configured.")

    }

    func handleAccessoryUwbDidStart(_ deviceID: Int) {
        infoLabelUpdate(with: "Accessory Session started.")

        // Update the device Status
        if let startedDevice = dataChannel.getDeviceFromUniqueID(deviceID) {
            startedDevice.blePeripheralStatus = statusRanging
        }

        for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
            if cell.uniqueID == deviceID {
                cell.selectAsset(.miniLocation)
            }
        }

        // Enables Location assets when Qorvo device starts ranging
        // TODO: Check if this is still necessary
        enableLocation(true)
    }

    func handleAccessoryUwbDidStop(_ deviceID: Int) {
        infoLabelUpdate(with: "Accessory Session stopped.")

        // Disconnect from device
        disconnectFromAccessory(deviceID)
    }

    func clearLocationFields() {
        distanceLabel.text  = "-"
        azimuthLabel.text   = "-"
        elevationLabel.text = "-"

        azimuthLabel.textColor   = .black
        elevationLabel.textColor = .black
    }

    func enableLocation(_ enable: Bool) {
        arrowImgView.isHidden = !enable
        feedbackDisabled      = !enable
    }

    func updateMiniFields(_ deviceID: Int) {

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
        if Settings().isDirectionEnable {
            azimuth =  Int( 90 * (Double(azimuthCheck)))
        } else {
            azimuth = Int(rad2deg(Double(azimuthCheck)))
        }

        for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
            if cell.uniqueID == deviceID {
                cell.distanceLabel.text = String(format: "%0.1f m", distance!)
                cell.azimuthLabel.text  = String(format: "%d°", azimuth)

                // Update mini arrow
                let radians: CGFloat = CGFloat(azimuth) * (.pi / 180)
                cell.miniArrow.transform = CGAffineTransform(rotationAngle: radians)
            }
        }
    }

    func updateLocationFields(_ deviceID: Int) {
        if selectedAccessory == deviceID {

            let currentDevice = dataChannel.getDeviceFromUniqueID(deviceID)
            if  currentDevice == nil { return }

            // Get updated location values
            let distance  = currentDevice?.uwbLocation?.distance
            let direction = currentDevice?.uwbLocation?.direction

            let azimuthCheck = azimuth((currentDevice?.uwbLocation?.direction)!)

            // Check if azimuth check calcul is a number (ie: not infinite)
            if azimuthCheck.isNaN {
                return
            }

            var azimuth = 0
            if Settings().isDirectionEnable {
                azimuth =  Int( 90 * (Double(azimuthCheck)))
            } else {
                azimuth = Int(rad2deg(Double(azimuthCheck)))
            }

            let elevation = Int(90 * elevation(direction!))

            // Update Label
            distanceLabel.text = String(format: "%0.1f m", distance!)
            azimuthLabel.text = String(format: "%d°", azimuth)

            // Update Elevation
            if Settings().isDirectionEnable {
                elevationLabel.text = String(format: "%d°", elevation)
            } else {
                elevationLabel.text = getElevationFromInt(elevation: currentDevice?.uwbLocation?.elevation)
            }

            if (currentDevice?.uwbLocation?.noUpdate)! {
                azimuthLabel.textColor = .lightGray
                elevationLabel.textColor = .lightGray
            } else {
                azimuthLabel.textColor = .black
                elevationLabel.textColor = .black
            }

            // Update Graphics
            setArrowAngle(newElevation: elevation, newAzimuth: azimuth)

            // Update Feedback Level
            setFeedbackLvl(distance: distance!)
        }
    }
}

// MARK: - `ARSessionDelegate`.
extension AccessoryDemoViewController: ARSessionDelegate {
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return false
    }
}

// MARK: - `NISessionDelegate`.
extension AccessoryDemoViewController: NISessionDelegate {

    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        guard object.discoveryToken == configuration?.accessoryDiscoveryToken else { return }

        // Prepare to send a message to the accessory.
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)

        let str = msg.map { String(format: "0x%02x, ", $0) }.joined()
        logger.info("Sending shareable configuration bytes: \(str)")

        // Send the message to the correspondent accessory.
        sendDataToAccessory(msg, deviceIDFromSession(session))
        infoLabelUpdate(with: "Sent shareable configuration data.")
    }

    func session(_ session: NISession, didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence, for object: NINearbyObject?) {
        print("Convergence Status:\(convergence.status)")
        // TODO: To Refactor delete to only know converged or not

        guard let accessory = object else { return}

        switch convergence.status {
        case .converged:
            print("Horizontal Angle: \(accessory.horizontalAngle)")
            print("verticalDirectionEstimate: \(accessory.verticalDirectionEstimate)")
            infoLabelUpdate(with: "Converged")
            isConverged = true
        case .notConverged([NIAlgorithmConvergenceStatus.Reason.insufficientLighting]):
            infoLabelUpdate(with: "More light required")
            isConverged = false
        default:
            infoLabelUpdate(with: "Try moving in a different direction...")
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

        updateLocationFields(deviceID)
        updateMiniFields(deviceID)

    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {

        // Retry the session only if the peer timed out.
        guard reason == .timeout else { return }
        infoLabelUpdate(with: "Session timed out")

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
        infoLabelUpdate(with: "Session was suspended.")
        let msg = Data([MessageId.stop.rawValue])

        sendDataToAccessory(msg, deviceIDFromSession(session))
    }

    func sessionSuspensionEnded(_ session: NISession) {
        infoLabelUpdate(with: "Session suspension ended.")
        // When suspension ends, restart the configuration procedure with the accessory.
        let msg = Data([MessageId.initialize.rawValue])

        sendDataToAccessory(msg, deviceIDFromSession(session))
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        let deviceID = deviceIDFromSession(session)

        switch error {
        case NIError.invalidConfiguration:
            // Debug the accessory data to ensure an expected format.
            infoLabelUpdate(with: "The accessory configuration data is invalid. Please debug it and try again.")
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
extension AccessoryDemoViewController {

    func infoLabelUpdate(with text: String) {
        logger.info("\(text)")
    }

    func connectToAccessory(_ deviceID: Int) {
         do {
             try dataChannel.connectPeripheral(deviceID)
         } catch {
             infoLabelUpdate(with: "Failed to connect to accessory: \(error)")
         }
    }

    func disconnectFromAccessory(_ deviceID: Int) {
         do {
             try dataChannel.disconnectPeripheral(deviceID)
         } catch {
             infoLabelUpdate(with: "Failed to disconnect from accessory: \(error)")
         }
     }

    func sendDataToAccessory(_ data: Data, _ deviceID: Int) {
         do {
             try dataChannel.sendData(data, deviceID)
         } catch {
             infoLabelUpdate(with: "Failed to send data to accessory: \(error)")
         }
     }

    func handleSessionInvalidation(_ deviceID: Int) {
        infoLabelUpdate(with: "Session invalidated. Restarting.")
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
        infoLabelUpdate(with: "Nearby Interactions access required. You can change access for NIAccessory in Settings.")

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

// MARK: - Utils.
// Provides the azimuth from an argument 3D directional.
func azimuth(_ direction: simd_float3) -> Float {
    if Settings().isDirectionEnable {
        return asin(direction.x)
    } else {
        return atan2(direction.x, direction.z)
    }
}

// Provides the elevation from the argument 3D directional.
func elevation(_ direction: simd_float3) -> Float {
    return atan2(direction.z, direction.y) + .pi / 2
}

// TODO: Refactor
func rad2deg(_ number: Double) -> Double {
    return number * 180 / .pi
}

func getDirectionFromHorizontalAngle(rad: Float) -> simd_float3 {
    print("Horizontal Angle in deg = \(rad2deg(Double(rad)))")
    return simd_float3(x: sin(rad), y: 0, z: cos(rad))
}

func getElevationFromInt(elevation: Int?) -> String {
    guard elevation != nil else {
        return "UNKNOWN"
    }
    // TODO: Use Localizable String
    switch elevation {
    case NINearbyObject.VerticalDirectionEstimate.above.rawValue:
        return "ABOVE"
    case NINearbyObject.VerticalDirectionEstimate.below.rawValue:
        return "BELOW"
    case NINearbyObject.VerticalDirectionEstimate.same.rawValue:
        return "SAME"
    case NINearbyObject.VerticalDirectionEstimate.aboveOrBelow.rawValue, NINearbyObject.VerticalDirectionEstimate.unknown.rawValue:
        return "UNKNOWN"
    default:
        return "UNKNOWN"
    }
}
