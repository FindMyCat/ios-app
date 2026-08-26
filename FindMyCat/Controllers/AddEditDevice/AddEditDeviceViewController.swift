//
//  AddEditDeviceController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import Foundation
import UIKit
import CocoaTextField

class AddEditDeviceViewController: UIViewController, UITextFieldDelegate {

    let sheetView = DismissableSheet()
    let scanningLabel = UILabel()
    var avatarEmojiView = AvatarEmojiView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    var deviceNameTextField = CocoaTextField()
    var uniqueIdReadOnlyTextField = CocoaTextField()
    var hostTextField = CocoaTextField()
    var portTextField = CocoaTextField()
    let connectionStatusLabel = UILabel()
    private var statusTimer: Timer?

    private var isInEditingMode = false
    private var deviceIdForEditing: Int!
    private var bleUniqueID: Int?

    let submitButton = UIButton()

    // Variables for Keyboard view frame control
    private var originalFrame: CGRect?
    private var isKeyboardShowing = false
    private var keyboardHeight: CGFloat = 0.0

    // MARK: - View Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.setHidesBackButton(true, animated: false)
        view.addSubview(sheetView)

        sheetView.showInView(view, height: 620)

        sheetView.translatesAutoresizingMaskIntoConstraints = false

        addAvatarEmojiView()

        addConnectionStatusLabel()

        addDeviceNameTextField()

        addUniqueIdReadOnlyTextField()

        addHostTextField()

        addPortTextField()

        addSubmitButton()

        // The tag may not be discovered yet, so the status timer keeps retrying the
        // connection; once connected it reads the current config (prefill below).
        NotificationCenter.default.addObserver(self, selector: #selector(configRead(_:)), name: Notification.Name(Constants.ConfigReadNotificationName), object: nil)

        statusTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateConnectionStatus), userInfo: nil, repeats: true)
        updateConnectionStatus()

        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop the retry timer (it retains self) and drop the link. The short delay
        // lets a just-sent Save write flush before disconnecting.
        statusTimer?.invalidate()
        statusTimer = nil

        if let bleId = bleUniqueID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                try? BLEDataCommunicationChannel.shared.disconnectPeripheral(bleId)
            }
        }
    }

    deinit {
        statusTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func updateConnectionStatus() {
        let text: String
        let color: UIColor

        if let bleId = bleUniqueID,
           let device = BLEDataCommunicationChannel.shared.getDeviceFromUniqueID(bleId) {
            // Keep retrying until connected; device discovery can lag the screen opening.
            if device.blePeripheral.state == .disconnected {
                BLEDataCommunicationChannel.shared.ensureConnected(bleId)
            }

            if device.blePeripheral.state == .connected, device.configCharacteristic != nil {
                text = "Connected"; color = .systemGreen
            } else {
                // connecting, disconnecting, or connected-but-not-ready all read as connecting.
                text = "Connecting…"; color = .systemOrange
            }
        } else {
            text = "Searching…"; color = .systemGray
        }

        connectionStatusLabel.text = text
        connectionStatusLabel.textColor = color
        avatarEmojiView.textField.layer.borderColor = color.withAlphaComponent(0.5).cgColor
        avatarEmojiView.textField.layer.borderWidth = 3
    }

    // Prefill host/port when the tag reports its current config.
    @objc private func configRead(_ notification: Notification) {
        guard let host = notification.userInfo?["host"] as? String,
              let port = notification.userInfo?["port"] as? UInt16 else { return }
        let reportedDeviceId = notification.userInfo?["deviceId"] as? String
        DispatchQueue.main.async {
            if !host.isEmpty { self.hostTextField.text = host }
            if port != 0 { self.portTextField.text = String(port) }
            if !self.isInEditingMode, let deviceId = reportedDeviceId, !deviceId.isEmpty {
                self.uniqueIdReadOnlyTextField.text = deviceId
            }
        }
    }

    init(uniqueId: String, emoji: String?, name: String, id: Int) {
        uniqueIdReadOnlyTextField.text = uniqueId
        avatarEmojiView.textField.text = emoji
        deviceNameTextField.text = name
        deviceIdForEditing = id
        bleUniqueID = Int(uniqueId)
        super.init(nibName: nil, bundle: nil)
    }

    init(uniqueId: String) {
        uniqueIdReadOnlyTextField.text = uniqueId
        bleUniqueID = Int(uniqueId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public setters

    public func setEditingMode(shouldBeInEditingMode: Bool) {
        isInEditingMode = shouldBeInEditingMode
    }

    // MARK: - Sub views setup
    private func addAvatarEmojiView() {
        avatarEmojiView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(avatarEmojiView)

        avatarEmojiView.layer.shadowColor = UIColor.black.cgColor
        avatarEmojiView.layer.shadowOpacity = 0.4
        avatarEmojiView.layer.shadowOffset = CGSize(width: 0, height: 2)
        avatarEmojiView.layer.shadowRadius = 40
        avatarEmojiView.layer.masksToBounds = false

        NSLayoutConstraint.activate([
            avatarEmojiView.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),

            avatarEmojiView.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 24),
            avatarEmojiView.widthAnchor.constraint(equalToConstant: 100),
            avatarEmojiView.heightAnchor.constraint(equalToConstant: 100)
        ])

    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    private func addScanningLabel() {
        sheetView.addSubview(scanningLabel)

        scanningLabel.text = "Add Device"
        scanningLabel.font = UIFont.boldSystemFont(ofSize: 18)

        scanningLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scanningLabel.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            scanningLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 24)
        ])
    }

    private func addDeviceNameTextField() {
        deviceNameTextField.delegate = self
        deviceNameTextField.placeholder = "Device Name"
        deviceNameTextField.inactiveHintColor = .systemGray3
        deviceNameTextField.activeHintColor = .black
        deviceNameTextField.focusedBackgroundColor = UIColor(red: 236/255, green: 239/255, blue: 239/255, alpha: 1)
        deviceNameTextField.defaultBackgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
        deviceNameTextField.borderColor = .black
        deviceNameTextField.errorColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 0.7)
        deviceNameTextField.borderWidth = 1
        deviceNameTextField.cornerRadius = 11

        deviceNameTextField.returnKeyType = .done

        sheetView.addSubview(deviceNameTextField)

        deviceNameTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            deviceNameTextField.widthAnchor.constraint(equalTo: sheetView.widthAnchor, constant: -100),
            deviceNameTextField.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            deviceNameTextField.topAnchor.constraint(equalTo: connectionStatusLabel.bottomAnchor, constant: 24)
        ])
    }

    // Todo: make it read only and able to copy the device id
    private func addUniqueIdReadOnlyTextField() {
        uniqueIdReadOnlyTextField.delegate = self
        uniqueIdReadOnlyTextField.placeholder = "Unique Id"
        uniqueIdReadOnlyTextField.inactiveHintColor = .systemGray3
        uniqueIdReadOnlyTextField.activeHintColor = .black
        uniqueIdReadOnlyTextField.focusedBackgroundColor = UIColor(red: 236/255, green: 239/255, blue: 239/255, alpha: 1)
        uniqueIdReadOnlyTextField.defaultBackgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
        uniqueIdReadOnlyTextField.borderColor = .black
        uniqueIdReadOnlyTextField.errorColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 0.7)
        uniqueIdReadOnlyTextField.borderWidth = 1
        uniqueIdReadOnlyTextField.cornerRadius = 11

        uniqueIdReadOnlyTextField.returnKeyType = .done
        uniqueIdReadOnlyTextField.isUserInteractionEnabled = false
        uniqueIdReadOnlyTextField.textColor = .systemGray

        sheetView.addSubview(uniqueIdReadOnlyTextField)

        uniqueIdReadOnlyTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            uniqueIdReadOnlyTextField.widthAnchor.constraint(equalTo: sheetView.widthAnchor, constant: -100),
            uniqueIdReadOnlyTextField.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            uniqueIdReadOnlyTextField.topAnchor.constraint(equalTo: deviceNameTextField.bottomAnchor, constant: 20)
        ])

    }

    private func addConnectionStatusLabel() {
        // Status text under the avatar; the avatar's ring (border) is tinted to match.
        connectionStatusLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        connectionStatusLabel.textColor = .systemGray
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.text = "—"
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(connectionStatusLabel)

        NSLayoutConstraint.activate([
            connectionStatusLabel.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            connectionStatusLabel.topAnchor.constraint(equalTo: avatarEmojiView.bottomAnchor, constant: 8)
        ])
    }

    private func styleConfigField(_ field: CocoaTextField, placeholder: String) {
        field.delegate = self
        field.placeholder = placeholder
        field.inactiveHintColor = .systemGray3
        field.activeHintColor = .black
        field.focusedBackgroundColor = UIColor(red: 236/255, green: 239/255, blue: 239/255, alpha: 1)
        field.defaultBackgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
        field.borderColor = .black
        field.errorColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 0.7)
        field.borderWidth = 1
        field.cornerRadius = 11
        field.returnKeyType = .done
        field.translatesAutoresizingMaskIntoConstraints = false
    }

    private func addHostTextField() {
        styleConfigField(hostTextField, placeholder: "Cloud Host / IP")
        sheetView.addSubview(hostTextField)

        NSLayoutConstraint.activate([
            hostTextField.widthAnchor.constraint(equalTo: sheetView.widthAnchor, constant: -100),
            hostTextField.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            hostTextField.topAnchor.constraint(equalTo: uniqueIdReadOnlyTextField.bottomAnchor, constant: 20)
        ])
    }

    private func addPortTextField() {
        styleConfigField(portTextField, placeholder: "Port")
        portTextField.keyboardType = .numberPad
        sheetView.addSubview(portTextField)

        NSLayoutConstraint.activate([
            portTextField.widthAnchor.constraint(equalTo: sheetView.widthAnchor, constant: -100),
            portTextField.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            portTextField.topAnchor.constraint(equalTo: hostTextField.bottomAnchor, constant: 20)
        ])
    }

    private func addSubmitButton() {

        sheetView.addSubview(submitButton)

        var configuration = UIButton.Configuration.tinted()
        configuration.cornerStyle = .large
        configuration.buttonSize = .large

        submitButton.configuration = configuration

        submitButton.tintColor = .systemBlue

        submitButton.setTitle("Save", for: .normal)

        submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: portTextField.bottomAnchor, constant: 50),
            submitButton.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 100)
        ])

        submitButton.addTarget(self, action: #selector(createOrEditDevice), for: .touchUpInside)
    }

    // MARK: - action handlers
    @objc func createOrEditDevice() {
        guard let deviceName = deviceNameTextField.text,
              let deviceUniqueId = uniqueIdReadOnlyTextField.text,
              let emoji = avatarEmojiView.textField.text
        else {
            return
        }

        // Push host/port to the tag over BLE. The device's uniqueId string is its
        // BLE uniqueID; no-op (throws) if the tag isn't currently connected.
        if let host = hostTextField.text, !host.isEmpty,
           let port = UInt16(portTextField.text ?? ""),
           let bleId = bleUniqueID {
            try? BLEDataCommunicationChannel.shared.sendConfig(host: host, port: port, deviceId: deviceUniqueId, bleId)
        }

        if isInEditingMode {
            #if DEBUG
            let bypassLogin = true
            if bypassLogin {
                self.navigationController?.dismiss(animated: true)
                return
            }
            #endif
            TraccarAPIManager.shared.updateDevice(name: deviceName, id: deviceIdForEditing, uniqueId: deviceUniqueId, emoji: emoji) {
                response in
                switch response {
                case .success:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        SharedData.shared.updateDataFromApi()
                }

                    self.dismiss(animated: true)
                default:
                    print("Could not update device")
                }
            }
        } else {
            #if DEBUG
            let bypassLogin = true
            if bypassLogin {
                let localDevice = Device(name: deviceName, id: 0, uniqueId: deviceUniqueId)
                localDevice.attributes = Device.Attributes(emoji: emoji.isEmpty ? nil : emoji)
                SharedData.addLocalDevice(localDevice)
                self.navigationController?.dismiss(animated: true)
                return
            }
            #endif
            TraccarAPIManager.shared.createDevice(name: deviceName, uniqueId: deviceUniqueId, emoji: emoji) {
                response in
                switch response {
                case .success:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        SharedData.shared.updateDataFromApi()
                    }
                    self.navigationController?.dismiss(animated: true)
                default:
                    print("Could not create device")
                }
            }
        }

    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        if keyboardFrame.origin.y >= UIScreen.main.bounds.size.height {
            // Keyboard is hidden
            isKeyboardShowing = false
            keyboardHeight = 0.0
        } else {
            // Keyboard is visible
            isKeyboardShowing = true
            keyboardHeight = keyboardFrame.size.height
        }

        adjustViewForKeyboard()
    }

    private func adjustViewForKeyboard() {
        if isKeyboardShowing {
            // Move the view up by the keyboard height
            view.frame.origin.y = -1.8 * keyboardHeight / 3
        } else {
            // Reset the view position
            view.frame.origin.y = 0
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard isKeyboardShowing, let originalFrame = originalFrame else { return }

        view.frame = originalFrame
        self.originalFrame = nil
        isKeyboardShowing = false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

           // Dismiss the keyboard

           return true
       }
}
