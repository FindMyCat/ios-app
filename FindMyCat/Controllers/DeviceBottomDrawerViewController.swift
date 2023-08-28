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

    var selectedDeviceLocationFetchProgressBarTimer: Timer?
    var selectedDeviceLocationFetchProgressBarPercent: CGFloat = 0

    func updateProgressOnLocationFetchButtonTimer() {
        selectedDeviceLocationFetchProgressBarTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(updateselectedDeviceLocationFetchProgressBarPercent), userInfo: nil, repeats: true)
    }

    @objc func updateselectedDeviceLocationFetchProgressBarPercent() {
        if selectedDeviceLocationFetchProgressBarPercent < 1.0 {
            selectedDeviceLocationFetchProgressBarPercent += 0.04
            reloadTableDataCellByCell()
        } else {
            selectedDeviceLocationFetchProgressBarPercent = 0
            selectedDeviceLocationFetchProgressBarTimer?.invalidate()
            reloadTableDataCellByCell()
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

        tableView.reloadData()
    }

    // MARK: - Notification Observers

    @objc private func devicesUpdated(_ notification: Notification) {

        let totalDevices = SharedData.getDevicesCount()
        let tableViewRows = tableView.numberOfRows(inSection: 0)

        if totalDevices != tableViewRows {
            if totalDevices > tableViewRows {
                let rowsToAdd = totalDevices - tableViewRows
                for index in 0..<rowsToAdd {
                    let indexPath = IndexPath(row: index + (totalDevices - 1), section: 0)
                    tableView.insertRows(at: [indexPath], with: .automatic)
                }
            }
            if totalDevices < tableViewRows {
                let rowsToRemove = tableViewRows - totalDevices
                for _ in 0..<rowsToRemove {
                    let indexPath = IndexPath(row: tableIndexToRemove!, section: 0)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
        }
        // update cells one by one to reduce flickers
       reloadTableDataCellByCell()
    }

    @objc private func positionsUpdated(_ notification: Notification) {
        // update cells one by one to reduce flickers
        reloadTableDataCellByCell()
    }

    func reloadTableDataCellByCell() {
        let sectionIndex = 0
        let totalRows = tableView.numberOfRows(inSection: sectionIndex)

        for row in 0..<totalRows {
            let indexPath = IndexPath(row: row, section: sectionIndex)
            tableView.reloadRows(at: [indexPath], with: .fade)
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
        cell.pingOrlostModeButton.setProgressBar(percent: selectedDeviceLocationFetchProgressBarPercent)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressButtonAction(_:)))
        cell.pingOrlostModeButton.addGestureRecognizer(longPressRecognizer)

        cell.currentMode = currentMode

        if let targetPosition = positions.first(where: { $0.deviceId == cellDevice.id }) {
            getAddressFromPosition(position: targetPosition) { [weak cell] address in
                guard let cell = cell else {
                    return // Cell is no longer available
                }

                let currentIndexPath = tableView.indexPath(for: cell)

                // Ensure the captured cell is still at the same index path
                if currentIndexPath == indexPath {
                    if address == nil {
                        cell.deviceAddressLabel.text = Constants.AddressUnavailable
                    } else {
                        cell.deviceAddressLabel.text = address
                    }

                    // Replace Address with Offline if lastUpdate is nil (never recieved update)
                    if cellDevice.lastUpdate != nil {
                        let lastSeen = DateTimeUtil.relativeTime(dateString: cellDevice.lastUpdate!)

                        cell.deviceAddressLabel.isHidden = false
                        cell.dotSeparatorView.isHidden = false

                        cell.lastSeenLabel.text = lastSeen
                        cell.lastSeenLabel.isHidden = false
                    }

                    // Set the battery percentage
                    cell.setBatteryPercentage(percentage: targetPosition.attributes.batteryLevel)

                    cell.batteryIcon.isHidden = false

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

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])

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
    }

    private func stopTimer() {
        tableReloadTimer?.invalidate()
        tableReloadTimer = nil
    }

}

extension DeviceBottomDrawerController: DeviceCellDelegate {
    func launchPreciseFindScreen() {

        guard selectedDeviceIndex != nil else {return}

        let selectedDevice = SharedData.getDevices()[selectedDeviceIndex!]
        let selectedDeviceName = selectedDevice.name
        let selectedDeviceUniqueBLEId = Int(selectedDevice.uniqueId)!

        let vc = PreciseFinderViewContoller(deviceDisplayName: selectedDeviceName, deviceUniqueBLEId: selectedDeviceUniqueBLEId)

        vc.modalPresentationStyle = .fullScreen

        parentVc.present(vc, animated: true)
    }

    func activateLostMode(currentMode: String) {

        updateProgressOnLocationFetchButtonTimer()
        guard selectedDeviceIndex != nil else {return}

        let selectedDevice = SharedData.getDevices()[selectedDeviceIndex!]
        let selectedDeviceUniqueBLEId = Int(selectedDevice.uniqueId)!

        HologramAPIManager.shared.fetchDevice(name: String(selectedDeviceUniqueBLEId), orgId: HologramAPIManager.shared.orgId) {
            result in

            switch result {
            case .success(let hologramDevice):
                // Send UDP message to device for lost mode activation
                HologramAPIManager.shared.sendCloudMessageToDevice(deviceId: hologramDevice.id, message: currentMode) {
                    result in

                    debugPrint(result)
                }

            case .failure(let error):
                self.logger.error("Could not fetch Hologram device info from REST endpoint \(error)")
            }
        }

    }
}
