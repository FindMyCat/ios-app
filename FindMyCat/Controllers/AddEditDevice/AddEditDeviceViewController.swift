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

    private var isInEditingMode = false
    private var deviceIdForEditing: Int!

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

        sheetView.showInView(view, height: 500)

        sheetView.translatesAutoresizingMaskIntoConstraints = false

        addAvatarEmojiView()

        addDeviceNameTextField()

        addUniqueIdReadOnlyTextField()

        addSubmitButton()

        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

    }

    init(uniqueId: String, emoji: String?, name: String, id: Int) {
        uniqueIdReadOnlyTextField.text = uniqueId
        avatarEmojiView.textField.text = emoji
        deviceNameTextField.text = name
        deviceIdForEditing = id
        super.init(nibName: nil, bundle: nil)
    }

    init(uniqueId: String) {
        uniqueIdReadOnlyTextField.text = uniqueId
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
            deviceNameTextField.topAnchor.constraint(equalTo: avatarEmojiView.bottomAnchor, constant: 50)
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

        sheetView.addSubview(uniqueIdReadOnlyTextField)

        uniqueIdReadOnlyTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            uniqueIdReadOnlyTextField.widthAnchor.constraint(equalTo: sheetView.widthAnchor, constant: -100),
            uniqueIdReadOnlyTextField.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            uniqueIdReadOnlyTextField.topAnchor.constraint(equalTo: deviceNameTextField.bottomAnchor, constant: 20)
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
            submitButton.topAnchor.constraint(equalTo: uniqueIdReadOnlyTextField.bottomAnchor, constant: 50),
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

        if isInEditingMode {
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
