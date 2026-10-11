//
//  DeviceBottomDrawerController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import Foundation
import UIKit
import FittedSheets
import CoreLocation
import os.log

class DeviceBottomDrawerController:
        UIViewController,
        UITableViewDelegate,
        UITableViewDataSource {
    public let controller: UIViewController

    // Parent View + Controller
    private var parentVc: UIViewController
    private var parentView: UIView

    // Views
    private var stackView = UIStackView()
    private var drawerLabel = UILabel()
    private var tableView = UITableView()
    private var addNewDeviceButton = UIButton()

    private var selectedDeviceIndex: Int?

    var currentMode: String = "ping" {
        didSet {
            reloadTableDataCellByCell()
        }
    }

    var cachedAddressesByDeviceId: [Int: (latitude: Double, longitude: Double, address: String?)] = [:]

    private let failedPingFeedbackGenerator = UINotificationFeedbackGenerator()

    private static let acknowledgedFailedPingIdsKey = "AcknowledgedFailedCommandEventIds"
    private static let playSoundHoldSeconds: TimeInterval = 5.0

    var alreadyAcknowledgedFailedPingIds: Set<Int> {
        get {
            let stored = UserDefaults.standard.array(forKey: Self.acknowledgedFailedPingIdsKey) as? [Int] ?? []
            return Set(stored)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Self.acknowledgedFailedPingIdsKey)
        }
    }

    var selectedDevicePingElapsedRedrawTimer: Timer?

    func startSelectedDevicePingElapsedRedrawTimer() {
        guard selectedDevicePingElapsedRedrawTimer == nil else { return }
        let selectedDevicePingElapsedTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(redrawSelectedDevicePingElapsedTitles), userInfo: nil, repeats: true)
        RunLoop.current.add(selectedDevicePingElapsedTimer, forMode: .common)
        selectedDevicePingElapsedRedrawTimer = selectedDevicePingElapsedTimer
    }

    func stopSelectedDevicePingElapsedRedrawTimer() {
        selectedDevicePingElapsedRedrawTimer?.invalidate()
        selectedDevicePingElapsedRedrawTimer = nil
    }

    @objc func redrawSelectedDevicePingElapsedTitles() {
        let devices = SharedData.getDevices()
        var anyDeviceHasPingInFlight = false

        for (row, device) in devices.enumerated() {
            guard let pingSentAt = SharedData.pingSentAt(forDeviceId: device.id) else { continue }
            anyDeviceHasPingInFlight = true

            let indexPath = IndexPath(row: row, section: 0)
            guard let cell = tableView.cellForRow(at: indexPath) as? DeviceTableViewCell else { continue }
            cell.pingOrlostModeButton.setPingInFlight(since: pingSentAt, idleTitle: currentMode.capitalized,
                                                      edrxSeconds: SharedData.edrxSeconds(forDeviceId: device.id))
        }

        if !anyDeviceHasPingInFlight {
            stopSelectedDevicePingElapsedRedrawTimer()
        }
    }

    @objc func longPressButtonAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            // Long press has started
            print("Long press started")
            currentMode = currentMode == "ping" ? "lost" : "ping"
        } else if sender.state == .ended {
            // Long press has ended
            print("Long press ended")
        }
    }

    // Timer to refresh table cell data
    private var tableReloadTimer: Timer?
    private var tableIndexToRemove: Int?

    let logger = Logger(subsystem: "ViewControllers", category: String(describing: DeviceBottomDrawerController.self))

    // MARK: - Initializers
    // Constructor
    init(parentView: UIView, parentVc: UIViewController) {
        self.parentVc = parentVc
        self.parentView = parentView

        controller = UIViewController()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        view.isUserInteractionEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(devicesUpdated(_:)), name: Notification.Name(Constants.DevicesUpdatedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionsUpdated(_:)), name: Notification.Name(Constants.PositionsUpdatedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pingsInFlightUpdated(_:)), name: Notification.Name(Constants.PingsInFlightUpdatedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceStatusUpdated(_:)), name: Notification.Name(Constants.DeviceStatusUpdatedNotificationName), object: nil)

        configureSheetController()

        tableView.register(DeviceTableViewCell.self, forCellReuseIdentifier: "DeviceCell")

        configureStackView()
        configureDrawerLabel()
        configureHairline()
        configureTableView()
        configureAddNewDeviceButton()

    }

    override func viewDidLayoutSubviews() {
        tableView.frame = controller.view.bounds
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startTimer()

        BLEDataCommunicationChannel.shared.identifyCollars()

        tableView.reloadData()
    }

    // MARK: - Notification Observers

    @objc private func devicesUpdated(_ notification: Notification) {

        let totalDevices = SharedData.getDevicesCount()
        let tableViewRows = tableView.numberOfRows(inSection: 0)

        if totalDevices > tableViewRows {
            let addedRowIndexPaths = (tableViewRows..<totalDevices).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: addedRowIndexPaths, with: .automatic)
        } else if totalDevices < tableViewRows {
            if let rowToRemove = tableIndexToRemove, tableViewRows - totalDevices == 1, rowToRemove < tableViewRows {
                tableView.deleteRows(at: [IndexPath(row: rowToRemove, section: 0)], with: .left)
                tableIndexToRemove = nil
            } else {
                tableView.reloadData()
                return
            }
        }
        // update cells one by one to reduce flickers
       reloadTableDataCellByCell()
    }

    @objc private func positionsUpdated(_ notification: Notification) {
        // update cells one by one to reduce flickers
        reloadTableDataCellByCell()
    }

    @objc private func pingsInFlightUpdated(_ notification: Notification) {
        reloadTableDataCellByCell()
    }

    @objc private func deviceStatusUpdated(_ notification: Notification) {
        guard let deviceStates = notification.userInfo?["deviceStates"] as? [Int: DeviceState] else { return }

        for (deviceId, state) in deviceStates {
            guard let result = state.command, result.status.lowercased() == "fail",
                  !alreadyAcknowledgedFailedPingIds.contains(result.id) else { continue }
            presentFailedPingAlert(for: result, deviceId: deviceId)
        }
    }

    private func presentFailedPingAlert(for result: CommandResult, deviceId: Int) {
        guard parentVc.presentedViewController == nil else { return }

        let deviceName = SharedData.getDevices().first(where: { $0.id == deviceId })?.name ?? "The collar"

        var message = "\(deviceName) heard the ping but could not get a location fix."
        if let searchedFor = result.elapsedSeconds.map(formattedSearchDuration) {
            message += " GPS searched for \(searchedFor)"
            if let satellitesTracked = result.satellites {
                message += " and tracked \(formattedSatelliteCount(satellitesTracked))"
            }
            message += "."
        } else if let satellitesTracked = result.satellites {
            message += " GPS tracked \(formattedSatelliteCount(satellitesTracked))."
        }

        if let failureReason = readableFailureReason(from: result) {
            message += "\n\nReason: \(failureReason)"
        }

        let alertController = UIAlertController(title: "No fix", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.alreadyAcknowledgedFailedPingIds.insert(result.id)
        })

        failedPingFeedbackGenerator.prepare()
        failedPingFeedbackGenerator.notificationOccurred(.warning)

        parentVc.present(alertController, animated: true, completion: nil)
    }

    private func formattedSatelliteCount(_ satellites: Double) -> String {
        let wholeSatellites = Int(satellites.rounded())
        return wholeSatellites == 1 ? "1 satellite" : "\(wholeSatellites) satellites"
    }

    private func formattedSearchDuration(_ seconds: Double) -> String {
        let wholeSeconds = Int(seconds.rounded())
        if wholeSeconds < 60 {
            return "\(wholeSeconds)s"
        }
        return "\(wholeSeconds / 60)m \(wholeSeconds % 60)s"
    }

    private func readableFailureReason(from result: CommandResult) -> String? {
        guard let reason = result.reason?.trimmingCharacters(in: .whitespaces),
              !reason.isEmpty,
              reason.lowercased() != "undefined",
              reason.lowercased() != "null" else {
            return nil
        }
        return reason
    }

    func reloadTableDataCellByCell() {
        let sectionIndex = 0
        let totalRows = tableView.numberOfRows(inSection: sectionIndex)

        for row in 0..<totalRows {
            let indexPath = IndexPath(row: row, section: sectionIndex)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    // MARK: - Configuration of all subviews

    private func configureSheetController() {
        let sheeetOptions = SheetOptions(
            useInlineMode: true,
            isRubberBandEnabled: true
        )

        let allowedSheetSizes = [SheetSize.percent(0.4), SheetSize.percent(0.7), SheetSize.percent(0.15)]

        let sheetController = SheetViewController(controller: self.controller, sizes: allowedSheetSizes, options: sheeetOptions)
        sheetController.allowGestureThroughOverlay = true

        sheetController.shouldDismiss = { _ in
        // This is called just before the sheet is dismissed. Return false to prevent the build in dismiss events
            return false
        }
        // The size of the grip in the pull bar
        sheetController.gripSize = CGSize(width: 50, height: 6)
        sheetController.gripColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.3)
        sheetController.overlayColor = UIColor.clear

        // The corner curve of the sheet (iOS 13 or later)
        sheetController.cornerCurve                 = .continuous

        // minimum distance above the pull bar, prevents bar from coming right up to the edge of the screen
        sheetController.minimumSpaceAbovePullBar    = 0

        // Determine if the rounding should happen on the pullbar or the presented controller only (should only be true when the pull bar's background color is .clear)
        sheetController.treatPullBarAsClear         = false

        // Disable the dismiss on background tap functionality
        sheetController.dismissOnOverlayTap         = false

        // Disable the ability to pull down to dismiss the modal
        sheetController.dismissOnPull               = false

        /// Allow pulling past the maximum height and bounce back. Defaults to true.
        sheetController.allowPullingPastMaxHeight   = false

        /// Automatically grow/move the sheet to accomidate the keyboard. Defaults to true.
        sheetController.autoAdjustToKeyboard        = true

        sheetController.contentBackgroundColor      = .clear

        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.backgroundColor = UIColor.init(red: 243/255, green: 243/255, blue: 243/255, alpha: 0.7)

        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.addSubview(blurEffectView)

        // Disable panning on Sheet when interacting with the table.
        sheetController.panGestureShouldBegin = {
            _ in

            return !self.tableView.isTracking && !self.addNewDeviceButton.isSelected
        }
        // animate in
        sheetController.animateIn(to: self.parentView, in: self.parentVc)
    }

    func configureStackView() {

        controller.view.addSubview(stackView)

        stackView.axis = .horizontal
        stackView.backgroundColor = .clear
        // constraints
        stackView.translatesAutoresizingMaskIntoConstraints                                                  = false
        stackView.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: 15).isActive            = true
        stackView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 15).isActive    = true
        stackView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -15).isActive = true
        stackView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: 15).isActive      = true
    }

    func configureDrawerLabel() {
        stackView.addSubview(drawerLabel)

        drawerLabel.text = "Devices"
        drawerLabel.font =  UIFont.boldSystemFont(ofSize: 18)
        drawerLabel.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        drawerLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true

        // constraints
        drawerLabel.translatesAutoresizingMaskIntoConstraints = false

    }

    func configureHairline() {
        let hairline = UIView()
        stackView.addSubview(hairline)
        hairline.translatesAutoresizingMaskIntoConstraints                                              = false
        hairline.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor).isActive            = true
        hairline.heightAnchor.constraint(equalToConstant: 0.3).isActive                                 = true
        hairline.leftAnchor.constraint(equalTo: controller.view.leftAnchor).isActive                    = true
        hairline.topAnchor.constraint(equalTo: drawerLabel.bottomAnchor, constant: 15).isActive          = true
        hairline.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.3)
    }

    func configureTableView() {

        tableView.delegate = self
        tableView.dataSource = self
        stackView.addSubview(tableView)

        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints                                             = false
        tableView.topAnchor.constraint(equalTo: drawerLabel.bottomAnchor, constant: 15).isActive        = true
        tableView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor).isActive             = true
        tableView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor).isActive           = true
        tableView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20).isActive       = true

    }

    func configureAddNewDeviceButton() {
        stackView.addSubview(addNewDeviceButton)

        let plusImageConfiguration = UIImage.SymbolConfiguration(pointSize: 23, weight: .medium)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusImageConfiguration)

        addNewDeviceButton.setImage(plusImage, for: .normal)

        addNewDeviceButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            addNewDeviceButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 10),
            addNewDeviceButton.centerXAnchor.constraint(equalTo: drawerLabel.centerXAnchor),
            addNewDeviceButton.widthAnchor.constraint(equalToConstant: 50)
        ])

        addNewDeviceButton.addTarget(self, action: #selector(addNewDeviceButtonClicked), for: .touchUpInside)
    }

    // MARK: - UITableView Delegate & DataSource

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceTableViewCell
        let devices = SharedData.getDevices()
        let positions = SharedData.getPositions()

        let cellDevice = devices[indexPath.row]

        cell.backgroundColor = .clear
        cell.delegate = self

        // Set the name
        cell.deviceNameLabel.text = cellDevice.name

        // Reset cell labels
        cell.dotSeparatorView.isHidden = true
        cell.lastSeenLabel.isHidden = true
        cell.deviceAddressLabel.isHidden = true
        cell.batteryIcon.isHidden = true
        cell.pingOrlostModeButton.setPingInFlight(since: SharedData.pingSentAt(forDeviceId: cellDevice.id), idleTitle: currentMode.capitalized,
                                                  edrxSeconds: SharedData.edrxSeconds(forDeviceId: cellDevice.id))

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressButtonAction(_:)))
        cell.pingOrlostModeButton.addGestureRecognizer(longPressRecognizer)

        cell.currentMode = currentMode

        if let targetPosition = positions.first(where: { $0.deviceId == cellDevice.id }) {

            let renderPositionDetailsOnCell: (String?) -> Void = { [weak cell] address in
                guard let cell = cell else {
                    return // Cell is no longer available
                }

                cell.deviceAddressLabel.text = address ?? Constants.AddressUnavailable

                // Replace Address with Offline if lastUpdate is nil (never recieved update)
                if cellDevice.lastUpdate != nil {
                    let lastPositionFixedAt = DateTimeUtil.relativeTime(dateString: targetPosition.fixTime)

                    cell.deviceAddressLabel.isHidden = false
                    cell.dotSeparatorView.isHidden = false

                    cell.lastSeenLabel.text = lastPositionFixedAt
                    cell.lastSeenLabel.isHidden = false
                }

                // Set the battery percentage
                if let batteryLevel = targetPosition.attributes?.batteryLevel {
                    cell.setBatteryPercentage(percentage: batteryLevel)
                    cell.batteryIcon.isHidden = false
                } else {
                    cell.batteryIcon.isHidden = true
                }
            }

            let cachedAddress = cachedAddressesByDeviceId[cellDevice.id]
            if let cachedAddress = cachedAddress,
               cachedAddress.latitude == targetPosition.latitude,
               cachedAddress.longitude == targetPosition.longitude {
                renderPositionDetailsOnCell(cachedAddress.address)
            } else {
                getAddressFromPosition(position: targetPosition) { [weak self, weak cell] address in
                    guard let self = self, let cell = cell else {
                        return // Cell is no longer available
                    }

                    self.cachedAddressesByDeviceId[cellDevice.id] = (targetPosition.latitude, targetPosition.longitude, address)

                    // Ensure the captured cell is still at the same index path
                    if tableView.indexPath(for: cell) == indexPath {
                        renderPositionDetailsOnCell(address)
                    }
                }
            }
        } else if cellDevice.lastUpdate == nil {
            cell.deviceAddressLabel.text = Constants.DeviceOffline
            cell.deviceAddressLabel.isHidden = false
        }
        if cellDevice.attributes?.emoji != nil {
            cell.emojiLabel.text = cellDevice.attributes?.emoji
        }

        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.3)
        cell.selectedBackgroundView = bgColorView

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedData.getDevices().count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // If already selected, de-select.
        if selectedDeviceIndex == indexPath.row {
            selectedDeviceIndex = nil
        } else {
            selectedDeviceIndex = indexPath.row
        }

        tableView.deselectRow(at: indexPath, animated: true)

        tableView.beginUpdates()

        tableView.endUpdates()

        var userInfo: [String: Any] = [:]
        if let selectedDeviceIndex = selectedDeviceIndex {
            userInfo["deviceId"] = SharedData.getDevices()[selectedDeviceIndex].id
        }
        NotificationCenter.default.post(name: Notification.Name(Constants.DeviceSelectedNotificationName), object: nil, userInfo: userInfo)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == selectedDeviceIndex {
                // Return the expanded height of the cell
                return 155 // Adjust the value based on your requirements
            } else {
                // Return the default/collapsed height of the cell
                return 68
            }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        logger.log("swipe on cell")

        let device = SharedData.getDevices()[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            // Perform delete action for the cell at indexPath
            let alertController = UIAlertController(title: "Remove Device", message: Constants.RemoveDeviceConfirmationMessage, preferredStyle: .alert)

            let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
                // Perform the action here after the user confirms
                self.tableIndexToRemove = indexPath.row
                TraccarAPIManager.shared.deleteDevice(id: device.id) {
                    _ in
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)

            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")

        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, completionHandler in
            // Perform edit action for the cell at indexPath

            let vc = AddEditDeviceViewController(uniqueId: device.uniqueId, emoji: (device.attributes?.emoji)!, name: device.name, id: device.id)

            self.parentVc.present(vc, animated: true)

            vc.setEditingMode(shouldBeInEditingMode: true)

            completionHandler(true)
        }
        editAction.image = UIImage(systemName: "pencil")

        let statusAction = UIContextualAction(style: .normal, title: "Status") { _, _, completionHandler in
            let vc = DeviceStatusViewController(deviceId: device.id, deviceName: device.name)
            self.parentVc.present(UINavigationController(rootViewController: vc), animated: true)
            completionHandler(true)
        }
        statusAction.image = UIImage(systemName: "waveform.path.ecg")
        statusAction.backgroundColor = .systemIndigo

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction, statusAction])

        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    // MARK: - Private Methods

    private func getAddressFromPosition(position: Position, completion: @escaping (String?) -> Void) {
        let longitude = position.longitude
        let latitude = position.latitude
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                self.logger.error("Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let placemark = placemarks?.first {
                // Retrieve the address information from the placemark
                // \(placemark.subThoroughfare ?? "") \(placemark.thoroughfare ?? ""),
                let address = "\(placemark.locality ?? ""), \(placemark.administrativeArea ?? "")"
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
    // MARK: - Button click handlers

    @objc func addNewDeviceButtonClicked() {
        let vc = ScanDevicesNavigationController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        parentVc.present(vc, animated: true)
    }

    // MARK: - Timer functions

    @objc private func tableReloadTimerAction() {

        // Reload all rows one by one, this prevents the whole table from flashing
        let sectionIndex = 0
        let totalRows = tableView.numberOfRows(inSection: sectionIndex)

        for row in 0..<totalRows {
            let indexPath = IndexPath(row: row, section: sectionIndex)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    private func startTimer() {
        // Invalidate any existing timer to prevent duplicates
        stopTimer()

        // Create a new timer and schedule it to repeat at the desired interval
        tableReloadTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(tableReloadTimerAction), userInfo: nil, repeats: true)

        let anyDeviceHasPingInFlight = SharedData.getDevices().contains { device in
            SharedData.pingSentAt(forDeviceId: device.id) != nil
        }
        if anyDeviceHasPingInFlight {
            startSelectedDevicePingElapsedRedrawTimer()
        }
    }

    private func stopTimer() {
        tableReloadTimer?.invalidate()
        tableReloadTimer = nil
        stopSelectedDevicePingElapsedRedrawTimer()
    }

}

extension DeviceBottomDrawerController: DeviceCellDelegate {
    private func resolveBLEId(for device: Device) -> Int? {
        if let identified = BLEDataCommunicationChannel.shared.getDeviceFromDeviceId(device.uniqueId) {
            return identified.bleUniqueID
        }
        return Int(device.uniqueId)
    }

    func launchPreciseFindScreen() {

        guard selectedDeviceIndex != nil else {return}

        let selectedDevice = SharedData.getDevices()[selectedDeviceIndex!]
        let selectedDeviceName = selectedDevice.name
        let selectedDeviceUniqueBLEId = resolveBLEId(for: selectedDevice) ?? 0

        let vc = PreciseFinderViewContoller(deviceDisplayName: selectedDeviceName, deviceUniqueBLEId: selectedDeviceUniqueBLEId)

        vc.modalPresentationStyle = .fullScreen

        parentVc.present(vc, animated: true)
    }

    func playSound() {
        guard selectedDeviceIndex != nil else { return }
        let selectedDevice = SharedData.getDevices()[selectedDeviceIndex!]
        guard let selectedDeviceUniqueBLEId = resolveBLEId(for: selectedDevice) else { return }

        BLEDataCommunicationChannel.shared.ensureConnected(selectedDeviceUniqueBLEId)
        setSoundButtonBusy(true)
        sendPlaySound(to: selectedDeviceUniqueBLEId, attemptsLeft: 8)
    }

    private func setSoundButtonBusy(_ busy: Bool) {
        guard let row = selectedDeviceIndex,
              let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? DeviceTableViewCell
        else { return }

        cell.soundButton.configuration?.showsActivityIndicator = busy
    }

    private func sendPlaySound(to bleId: Int, attemptsLeft: Int) {
        guard attemptsLeft > 0 else {
            logger.error("playSound gave up, \(bleId) never became ready")
            setSoundButtonBusy(false)
            return
        }

        if let device = BLEDataCommunicationChannel.shared.getDeviceFromUniqueID(bleId),
           device.blePeripheral.state == .connected,
           device.rxCharacteristic != nil {
            try? BLEDataCommunicationChannel.shared.sendData(Data([MessageId.playSound.rawValue]), bleId)
            setSoundButtonBusy(false)

            // Release it, or Precise Find's connectPeripheral rejects a device that is
            // no longer statusDiscovered.
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.playSoundHoldSeconds) {
                try? BLEDataCommunicationChannel.shared.disconnectPeripheral(bleId)
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendPlaySound(to: bleId, attemptsLeft: attemptsLeft - 1)
        }
    }

    func activateLostMode(currentMode: String) {

        guard selectedDeviceIndex != nil else {return}

        let selectedDevice = SharedData.getDevices()[selectedDeviceIndex!]
        let selectedDeviceTraccarId = selectedDevice.id

        HologramAPIManager.shared.fetchDevice(name: selectedDevice.uniqueId, orgId: HologramAPIManager.shared.orgId) {
            result in

            switch result {
            case .success(let hologramDevice):
                // Send UDP message to device for lost mode activation
                HologramAPIManager.shared.sendCloudMessageToDevice(deviceId: hologramDevice.id, message: currentMode) {
                    result in

                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            SharedData.markPingSent(forDeviceId: selectedDeviceTraccarId)
                            self.startSelectedDevicePingElapsedRedrawTimer()
                            self.reloadTableDataCellByCell()
                        }
                    case .failure(let error):
                        self.logger.error("Could not queue command with Hologram \(error)")
                    }
                }

            case .failure(let error):
                self.logger.error("Could not fetch Hologram device info from REST endpoint \(error)")
            }
        }

    }
}
