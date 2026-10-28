//
//  UpdateViewController.swift
//  FindMyCat
//

import NordicDFU
import UIKit

/// Updates both chips to the latest firmware. First the nRF52 over Bluetooth
/// (skipped when the collar isn't in range), then the nRF91 over LTE: sends the
/// update command and follows download progress, the reboot and the new
/// version checking in. It can't be swiped away; Close appears once the update
/// finishes, fails or stalls.
class UpdateViewController: UIViewController {
    private let deviceId: Int
    private let uniqueId: String
    private let deviceName: String
    private let includeLTE: Bool
    private var startedAt = Date()
    private var dfuController: DFUServiceController?
    private var dfuPeripheralID: UUID?
    /// Covers the collar's 60 s watchdog if the new app stalls on its first boot.
    private static let backTimeout: TimeInterval = 90
    private var lastChangeAt = Date()
    private var lastStep = ""
    private var pollTimer: Timer?

    private static let pollInterval: TimeInterval = 3
    /// No new step for this long and the update is reported as stalled.
    private static let stallTimeout: TimeInterval = 10 * 60
    /// Server timestamps are whole seconds and phone clocks drift a little.
    private static let clockSlack: TimeInterval = 5

    private let stepLabel = UILabel()
    private let detailLabel = UILabel()
    private let collarView = CollarModelView()
    private let closeButton = UIButton(type: .system)

    init(deviceId: Int, uniqueId: String, deviceName: String, includeLTE: Bool) {
        self.deviceId = deviceId
        self.uniqueId = uniqueId
        self.deviceName = deviceName
        self.includeLTE = includeLTE
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Updating \(deviceName)"
        titleLabel.font = .preferredFont(forTextStyle: .title2)

        stepLabel.font = .preferredFont(forTextStyle: .headline)
        stepLabel.numberOfLines = 0
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0

        closeButton.setTitle("Close", for: .normal)
        closeButton.isHidden = true
        closeButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, collarView, stepLabel, detailLabel, closeButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            collarView.heightAnchor.constraint(equalTo: collarView.widthAnchor)
        ])

        updateBluetoothChip()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pollTimer?.invalidate()
    }

    private func sendCommand() {
        startedAt = Date()
        lastChangeAt = Date()
        collarView.setLED(.off)
        show(step: "LTE chip: sending…", detail: "Asking the cloud to send the update command.", progress: 0)
        DeviceCommandsAPIManager.shared.send("update", toDeviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.show(step: "Sent to the collar",
                          detail: "It hears the command at its next paging window, then starts downloading.",
                          progress: 0)
                self.pollTimer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
                    self?.poll()
                }
            case .failure(let error):
                self.finish(step: "Could not send the update", detail: error.localizedDescription)
            }
        }
    }

    private func poll() {
        DeviceStatusAPIManager.shared.fetchDeviceState(deviceId: deviceId) { [weak self] result in
            guard let self, case .success(let state) = result else { return }
            self.apply(state)
        }
    }

    private func apply(_ state: DeviceState) {
        let since = startedAt.addingTimeInterval(-Self.clockSlack)

        // The new image booted and checked in over LTE.
        if let firmware = state.firmware, firmware.receivedAt >= since {
            collarView.setLED(.blinkTwice(.systemBlue))
            finish(step: "✓ Running \(firmware.version)",
                   detail: "The update is installed and confirmed.", progress: 1)
            return
        }

        if let command = state.command, command.command == "update", command.receivedAt >= since {
            switch command.status {
            case "downloading":
                let percent = Float(command.reason?.dropLast() ?? "0") ?? 0
                collarView.setLED(.pulse(.systemBlue))
                show(step: "Downloading", detail: "\(Int(percent))% of the new firmware received.",
                     progress: percent / 100)
            case "ok":
                collarView.setLED(.off)
                show(step: "Installed, rebooting…",
                     detail: "The collar restarts into the new firmware and reports in once LTE is back.",
                     progress: 1)
            case "fail":
                collarView.setLED(.steady(.systemRed))
                finish(step: "Update failed", detail: command.reason ?? "The collar did not say why.")
                return
            default:
                break
            }
        }

        if Date().timeIntervalSince(lastChangeAt) > Self.stallTimeout {
            finish(step: "No word from the collar",
                   detail: "Nothing new for 10 minutes. It may not have LTE right now; the Status screen shows the update if it finishes later.")
        }
    }

    private func show(step: String, detail: String, progress: Float) {
        if step != lastStep || detail != detailLabel.text {
            lastChangeAt = Date()
        }
        lastStep = step
        stepLabel.text = step
        detailLabel.text = detail
        collarView.setProgress(progress, animated: true)
    }

    private func finish(step: String, detail: String, progress: Float? = nil) {
        pollTimer?.invalidate()
        BLEDataCommunicationChannel.shared.resumeScanning()
        show(step: step, detail: detail, progress: progress ?? collarView.progress)
        closeButton.setTitle("Close", for: .normal)
        closeButton.isHidden = false
        isModalInPresentation = false
    }

    /// Same lookup and 0.5 s retry as the add/edit screen: keeps searching until
    /// the collar is discovered. The DFU library makes its own connection.
    private func updateBluetoothChip() {
        show(step: "Bluetooth chip: searching…", detail: "Bring the phone next to the collar.", progress: 0)
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.isHidden = false

        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self, let bleId = Int(self.uniqueId),
                  let device = BLEDataCommunicationChannel.shared.getDeviceFromUniqueID(bleId) else { return }
            timer.invalidate()
            self.closeButton.isHidden = true
            self.downloadBluetoothFirmware(for: device)
        }
        pollTimer?.fire()
    }

    private func downloadBluetoothFirmware(for device: PreciseFindableDevice) {
        show(step: "Bluetooth chip: downloading…", detail: "Getting the latest Bluetooth firmware from the cloud.", progress: 0)
        DeviceCommandsAPIManager.shared.downloadFirmware("indoor_update.zip") { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                self.startDFU(zip: url, device: device)
            case .failure(let error):
                self.finish(step: "Could not download the Bluetooth update", detail: error.localizedDescription)
            }
        }
    }

    private func startDFU(zip: URL, device: PreciseFindableDevice) {
        let firmware: DFUFirmware
        do {
            firmware = try DFUFirmware(urlToZipFile: zip)
        } catch {
            finish(step: "Bluetooth update file is invalid", detail: error.localizedDescription)
            return
        }

        // The app's own connection and scanning would fight the DFU library for the collar.
        BLEDataCommunicationChannel.shared.pauseScanning()
        try? BLEDataCommunicationChannel.shared.disconnectPeripheral(device.bleUniqueID)

        dfuPeripheralID = device.blePeripheral.identifier
        let initiator = DFUServiceInitiator().with(firmware: firmware)
        initiator.delegate = self
        initiator.progressDelegate = self
        dfuController = initiator.start(targetWithIdentifier: device.blePeripheral.identifier)
        if dfuController == nil {
            finish(step: "Could not start the Bluetooth update", detail: "The collar isn't reachable over Bluetooth.")
        }
    }

    /// The bootloader accepted the image; success only once the collar's own
    /// advert (not DfuTarg) shows up again, i.e. the new app is running.
    private func waitForCollarBack() {
        show(step: "Bluetooth chip: restarting…", detail: "Waiting for the collar to come back.", progress: 1)
        BLEDataCommunicationChannel.shared.resumeScanning()
        let sentAt = Int64((Date().timeIntervalSince1970 * 1000).rounded())
        let deadline = Date().addingTimeInterval(Self.backTimeout)

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            let back = BLEDataCommunicationChannel.shared.preciseFindableDevices.contains {
                $0?.blePeripheral.identifier == self.dfuPeripheralID && ($0?.bleTimestamp ?? 0) > sentAt
            }
            if back {
                timer.invalidate()
                if self.includeLTE {
                    self.sendCommand()
                } else {
                    self.collarView.setLED(.blinkTwice(.systemBlue))
                    self.finish(step: "✓ Bluetooth chip updated", detail: "The collar is back on the new firmware.", progress: 1)
                }
            } else if Date() > deadline {
                timer.invalidate()
                self.collarView.setLED(.steady(.systemRed))
                self.finish(step: "Collar didn't come back",
                            detail: "The update was installed but the collar hasn't shown up over Bluetooth. Check it's powered and nearby.")
            }
        }
    }
}

extension UpdateViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .connecting:
            collarView.setLED(.pulse(.systemBlue))
            show(step: "Bluetooth chip: connecting…", detail: "Keep the phone next to the collar.", progress: 0)
        case .enablingDfuMode:
            show(step: "Bluetooth chip: restarting into the bootloader…", detail: "The collar reappears as DfuTarg.", progress: 0)
        case .starting, .validating:
            show(step: "Bluetooth chip: checking…", detail: "The collar verifies the signature.", progress: collarView.progress)
        case .completed:
            waitForCollarBack()
        case .aborted:
            collarView.setLED(.steady(.systemRed))
            finish(step: "Bluetooth update stopped",
                   detail: "If the collar shows up as DfuTarg, run the update again to recover it.")
        default:
            break
        }
    }

    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        collarView.setLED(.steady(.systemRed))
        finish(step: "Bluetooth update failed",
               detail: "\(message)\nIf the collar shows up as DfuTarg, run the update again to recover it.")
    }
}

extension UpdateViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        show(step: "Bluetooth chip: sending", detail: "\(progress)% sent.", progress: Float(progress) / 100)
    }
}
