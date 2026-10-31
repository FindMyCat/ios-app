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

    // MARK: - Constants

    private static let BLUETOOTH_CHIP_STEP_NUMBER = 1
    private static let LTE_CHIP_STEP_NUMBER = 2
    private static let TOTAL_STEP_COUNT_WITH_LTE = 2

    private static let COLLAR_SEARCH_RETRY_INTERVAL_SECONDS: TimeInterval = 0.5
    private static let COLLAR_RESTART_CHECK_INTERVAL_SECONDS: TimeInterval = 1
    private static let COLLAR_RESTART_TIMEOUT_SECONDS: TimeInterval = 90

    private static let LTE_STATUS_POLL_INTERVAL_SECONDS: TimeInterval = 3
    private static let LTE_UPDATE_STALL_TIMEOUT_SECONDS: TimeInterval = 10 * 60
    /// Server timestamps are whole seconds and phone clocks drift a little.
    private static let SERVER_CLOCK_SLACK_SECONDS: TimeInterval = 5

    private static let BLUETOOTH_CHIP_FIRMWARE_FILE_NAME = "indoor_update.zip"
    private static let COLLAR_PREVIEW_SIDE_LENGTH: CGFloat = 350

    private static let RESTARTING_STATUS_TITLE = "Restarting…"
    private static let UPDATE_COMPLETE_STATUS_TITLE = "Update complete"
    private static let UPDATE_FAILED_STATUS_TITLE = "Update failed"
    private static let KEEP_PHONE_NEAR_COLLAR_STATUS_DETAIL = "Keep your phone next to the collar."

    // MARK: - Collar

    private let deviceId: Int
    private let deviceUniqueId: String
    private let deviceName: String
    private let shouldUpdateLteChip: Bool

    // MARK: - Update state

    private var activeStepTimer: Timer?
    private var bluetoothFirmwareInstallController: DFUServiceController?
    private var collarBluetoothPeripheralIdentifier: UUID?
    private var lteUpdateCommandSentAt = Date()
    private var lastStatusChangeAt = Date()
    private var lastShownStatusTitle = ""

    // MARK: - Views

    private let stepCounterLabel = UILabel()
    private let collarModelView = CollarModelView()
    private let resultIconImageView = UIImageView()
    private let statusTitleLabel = UILabel()
    private let statusDetailLabel = UILabel()
    private let bottomButton = UIButton(configuration: .filled())

    // MARK: - Lifecycle

    init(deviceId: Int, deviceUniqueId: String, deviceName: String, shouldUpdateLteChip: Bool) {
        self.deviceId = deviceId
        self.deviceUniqueId = deviceUniqueId
        self.deviceName = deviceName
        self.shouldUpdateLteChip = shouldUpdateLteChip
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        searchForCollarOverBluetooth()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        activeStepTimer?.invalidate()
    }

    // MARK: - Layout

    private func buildLayout() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Updating \(deviceName)"
        titleLabel.font = Self.boldFont(.title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        stepCounterLabel.font = .preferredFont(forTextStyle: .subheadline)
        stepCounterLabel.adjustsFontForContentSizeCategory = true
        stepCounterLabel.textColor = .secondaryLabel
        stepCounterLabel.textAlignment = .center

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, stepCounterLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        resultIconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle)
        resultIconImageView.contentMode = .scaleAspectFit
        resultIconImageView.isHidden = true

        statusTitleLabel.font = Self.boldFont(.title3)
        statusTitleLabel.adjustsFontForContentSizeCategory = true
        statusTitleLabel.textAlignment = .center
        statusTitleLabel.numberOfLines = 0

        statusDetailLabel.font = .preferredFont(forTextStyle: .body)
        statusDetailLabel.adjustsFontForContentSizeCategory = true
        statusDetailLabel.textColor = .secondaryLabel
        statusDetailLabel.textAlignment = .center
        statusDetailLabel.numberOfLines = 0

        let statusStack = UIStackView(arrangedSubviews: [resultIconImageView, statusTitleLabel, statusDetailLabel])
        statusStack.axis = .vertical
        statusStack.alignment = .center
        statusStack.spacing = 8

        bottomButton.isHidden = true
        bottomButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        for subview in [headerStack, collarModelView, statusStack, bottomButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            headerStack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),

            collarModelView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 32),
            collarModelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collarModelView.widthAnchor.constraint(equalToConstant: Self.COLLAR_PREVIEW_SIDE_LENGTH),
            collarModelView.heightAnchor.constraint(equalTo: collarModelView.widthAnchor),

            statusStack.topAnchor.constraint(equalTo: collarModelView.bottomAnchor, constant: 24),
            statusStack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            statusStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            statusStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomButton.topAnchor, constant: -16),

            bottomButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            bottomButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            bottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Step 1: Bluetooth chip

    /// Same lookup and 0.5 s retry as the add/edit screen: keeps searching until
    /// the collar is discovered. The DFU library makes its own connection.
    private func searchForCollarOverBluetooth() {
        showStepCounter(Self.BLUETOOTH_CHIP_STEP_NUMBER)
        showUpdateStatus(title: "Looking for the collar…", detail: "Hold your phone next to it.", progress: 0)
        showBottomButton(title: "Cancel", isProminent: false)

        activeStepTimer = Timer.scheduledTimer(withTimeInterval: Self.COLLAR_SEARCH_RETRY_INTERVAL_SECONDS, repeats: true) { [weak self] timer in
            guard let self, let collarBluetoothUniqueId = Int(self.deviceUniqueId),
                  let collar = BLEDataCommunicationChannel.shared.getDeviceFromUniqueID(collarBluetoothUniqueId) else { return }
            timer.invalidate()
            self.bottomButton.isHidden = true
            self.downloadBluetoothChipFirmware(for: collar)
        }
        activeStepTimer?.fire()
    }

    private func downloadBluetoothChipFirmware(for collar: PreciseFindableDevice) {
        showUpdateStatus(title: "Getting the update…", detail: "Downloading the latest firmware.", progress: 0)
        DeviceCommandsAPIManager.shared.downloadFirmware(Self.BLUETOOTH_CHIP_FIRMWARE_FILE_NAME) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let firmwareZipFileUrl):
                self.installBluetoothChipFirmware(from: firmwareZipFileUrl, on: collar)
            case .failure(let error):
                self.finishUpdate(title: "Could not download the update", detail: error.localizedDescription)
            }
        }
    }

    private func installBluetoothChipFirmware(from firmwareZipFileUrl: URL, on collar: PreciseFindableDevice) {
        let firmware: DFUFirmware
        do {
            firmware = try DFUFirmware(urlToZipFile: firmwareZipFileUrl)
        } catch {
            finishUpdate(title: "Update file is invalid", detail: error.localizedDescription)
            return
        }

        // The app's own connection and scanning would fight the DFU library for the collar.
        BLEDataCommunicationChannel.shared.pauseScanning()
        try? BLEDataCommunicationChannel.shared.disconnectPeripheral(collar.bleUniqueID)

        collarBluetoothPeripheralIdentifier = collar.blePeripheral.identifier
        let firmwareInstallInitiator = DFUServiceInitiator().with(firmware: firmware)
        firmwareInstallInitiator.delegate = self
        firmwareInstallInitiator.progressDelegate = self
        bluetoothFirmwareInstallController = firmwareInstallInitiator.start(targetWithIdentifier: collar.blePeripheral.identifier)
        if bluetoothFirmwareInstallController == nil {
            finishUpdate(title: "Could not start the update", detail: "Move closer to the collar and try again.")
        }
    }

    /// The bootloader accepted the image; success only once the collar's own
    /// advert (not DfuTarg) shows up again, i.e. the new app is running.
    private func waitForCollarToRestartAfterBluetoothInstall() {
        showUpdateStatus(title: Self.RESTARTING_STATUS_TITLE, detail: "Waiting for the collar to come back.", progress: 1)
        BLEDataCommunicationChannel.shared.resumeScanning()
        let installFinishedAtMilliseconds = Int64((Date().timeIntervalSince1970 * 1000).rounded())
        let restartDeadline = Date().addingTimeInterval(Self.COLLAR_RESTART_TIMEOUT_SECONDS)

        activeStepTimer?.invalidate()
        activeStepTimer = Timer.scheduledTimer(withTimeInterval: Self.COLLAR_RESTART_CHECK_INTERVAL_SECONDS, repeats: true) { [weak self] timer in
            guard let self else { return }
            let collarIsAdvertisingAgain = BLEDataCommunicationChannel.shared.preciseFindableDevices.contains {
                $0?.blePeripheral.identifier == self.collarBluetoothPeripheralIdentifier
                    && ($0?.bleTimestamp ?? 0) > installFinishedAtMilliseconds
            }
            if collarIsAdvertisingAgain {
                timer.invalidate()
                if self.shouldUpdateLteChip {
                    self.sendLteUpdateCommand()
                } else {
                    self.finishUpdate(title: Self.UPDATE_COMPLETE_STATUS_TITLE, detail: "\(self.deviceName) is back on the new firmware.",
                                      progress: 1, succeeded: true)
                }
            } else if Date() > restartDeadline {
                timer.invalidate()
                self.finishUpdate(title: "Collar didn't come back",
                                  detail: "The update installed, but the collar hasn't reappeared. Check it's powered on and nearby.")
            }
        }
    }

    // MARK: - Step 2: LTE chip

    private func sendLteUpdateCommand() {
        lteUpdateCommandSentAt = Date()
        lastStatusChangeAt = Date()
        showStepCounter(Self.LTE_CHIP_STEP_NUMBER)
        showUpdateStatus(title: "Sending update…", detail: "Asking the cloud to pass the update to the collar.", progress: 0)
        DeviceCommandsAPIManager.shared.send("update", toDeviceId: deviceId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.showUpdateStatus(title: "Waiting for the collar…",
                                      detail: "It picks up the update at its next check-in, then starts downloading.",
                                      progress: 0)
                self.activeStepTimer = Timer.scheduledTimer(withTimeInterval: Self.LTE_STATUS_POLL_INTERVAL_SECONDS, repeats: true) { [weak self] _ in
                    self?.fetchCollarStateDuringLteUpdate()
                }
            case .failure(let error):
                self.finishUpdate(title: "Could not send the update", detail: error.localizedDescription)
            }
        }
    }

    private func fetchCollarStateDuringLteUpdate() {
        DeviceStatusAPIManager.shared.fetchDeviceState(deviceId: deviceId) { [weak self] result in
            guard let self, case .success(let collarState) = result else { return }
            self.showLteUpdateProgress(from: collarState)
        }
    }

    private func showLteUpdateProgress(from collarState: DeviceState) {
        let reportsAfterCommandSentAt = lteUpdateCommandSentAt.addingTimeInterval(-Self.SERVER_CLOCK_SLACK_SECONDS)

        // The new image booted and checked in over LTE.
        if let firmware = collarState.firmware, firmware.receivedAt >= reportsAfterCommandSentAt {
            finishUpdate(title: Self.UPDATE_COMPLETE_STATUS_TITLE,
                         detail: "\(deviceName) is running \(firmware.version).", progress: 1, succeeded: true)
            return
        }

        if let command = collarState.command, command.command == "update", command.receivedAt >= reportsAfterCommandSentAt {
            switch command.status {
            case "downloading":
                let downloadPercent = Float(command.reason?.dropLast() ?? "0") ?? 0
                showUpdateStatus(title: "Downloading \(Int(downloadPercent))%", progress: downloadPercent / 100)
            case "ok":
                showUpdateStatus(title: Self.RESTARTING_STATUS_TITLE,
                                 detail: "This might take a while.",
                                 progress: 1)
            case "fail":
                finishUpdate(title: Self.UPDATE_FAILED_STATUS_TITLE, detail: command.reason ?? "Unknown failure reason.")
                return
            default:
                break
            }
        }

        if Date().timeIntervalSince(lastStatusChangeAt) > Self.LTE_UPDATE_STALL_TIMEOUT_SECONDS {
            finishUpdate(title: "Did not receive an update from the collar")
        }
    }

    // MARK: - Screen updates

    private func showStepCounter(_ stepNumber: Int) {
        stepCounterLabel.text = shouldUpdateLteChip ? "Step \(stepNumber) of \(Self.TOTAL_STEP_COUNT_WITH_LTE)" : nil
    }

    private func showUpdateStatus(title: String, detail: String? = nil, progress: Float) {
        if title != lastShownStatusTitle || detail != statusDetailLabel.text {
            lastStatusChangeAt = Date()
        }
        lastShownStatusTitle = title
        statusTitleLabel.text = title
        statusDetailLabel.text = detail
        statusDetailLabel.isHidden = detail == nil
        collarModelView.setProgress(progress, animated: true)
    }

    private func finishUpdate(title: String, detail: String? = nil, progress: Float? = nil, succeeded: Bool = false) {
        activeStepTimer?.invalidate()
        BLEDataCommunicationChannel.shared.resumeScanning()
        showUpdateStatus(title: title, detail: detail, progress: progress ?? collarModelView.progress)
        resultIconImageView.image = UIImage(systemName: succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        resultIconImageView.tintColor = succeeded ? .systemGreen : .systemOrange
        resultIconImageView.isHidden = false
        showBottomButton(title: succeeded ? "Done" : "Close", isProminent: true)
        isModalInPresentation = false
    }

    private func showBottomButton(title: String, isProminent: Bool) {
        var configuration: UIButton.Configuration = isProminent ? .filled() : .gray()
        configuration.title = title
        configuration.cornerStyle = .large
        configuration.buttonSize = .large
        bottomButton.configuration = configuration
        bottomButton.isHidden = false
    }

    private static func boldFont(_ textStyle: UIFont.TextStyle) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        return UIFont(descriptor: descriptor.withSymbolicTraits(.traitBold) ?? descriptor, size: 0)
    }
}

// MARK: - Bluetooth chip install callbacks

extension UpdateViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .connecting:
            showUpdateStatus(title: "Connecting…", detail: Self.KEEP_PHONE_NEAR_COLLAR_STATUS_DETAIL, progress: 0)
        case .enablingDfuMode:
            showUpdateStatus(title: "Preparing the collar…", detail: "It restarts into update mode.", progress: 0)
        case .starting, .validating:
            showUpdateStatus(title: "Verifying…", detail: "The collar checks the update is genuine.", progress: collarModelView.progress)
        case .completed:
            waitForCollarToRestartAfterBluetoothInstall()
        case .aborted:
            finishUpdate(title: "Update stopped")
        default:
            break
        }
    }

    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        finishUpdate(title: Self.UPDATE_FAILED_STATUS_TITLE,
                     detail: "\(message). Please try again.")
    }
}

extension UpdateViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        showUpdateStatus(title: "Installing \(progress)%", detail: Self.KEEP_PHONE_NEAR_COLLAR_STATUS_DETAIL, progress: Float(progress) / 100)
    }
}
