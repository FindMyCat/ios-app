//
//  AddDeviceViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/9/23.
//

import Foundation
import UIKit
import FittedSheets

class ScanDevicesViewController: UIViewController {

    let sheetView = DismissableSheet()
    let scanningLabel = UILabel()
    var scanningAnimationView: ScanningAnimationView!
    var circularLayout: CircularViewLayout!

    override func viewDidLoad() {

        super.viewDidLoad()

        addSheet()

        addScanningView()

        addScanningLabel()

        addCircularView()

        // Register for scanning devices notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: Notification.Name(Constants.PreciseFindableDevicesUpdatedNotificationName), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scanningAnimationView.startAnimation()
    }

    func addSheet() {
        view.addSubview(sheetView)

        sheetView.showInView(view, height: 500)
    }

    func addScanningView() {

        // Create the scanning view
        scanningAnimationView = ScanningAnimationView(frame: CGRect(x: 0, y: 70, width: sheetView.frame.width, height: sheetView.frame.height))

        sheetView.addSubview(scanningAnimationView)

    }

    func addScanningLabel() {
        sheetView.addSubview(scanningLabel)

        scanningLabel.text = "Add Device"
        scanningLabel.font = UIFont.boldSystemFont(ofSize: 18)

        scanningLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scanningLabel.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            scanningLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 24)
        ])
    }

    func addCircularView() {
        circularLayout = CircularViewLayout(frame: CGRect(x: 0, y: 70, width: sheetView.bounds.width, height: sheetView.bounds.height - 70))
        circularLayout.backgroundColor = .clear

        let circleSize = CGFloat(100)

        for (_, scannedDevice) in BLEDataCommunicationChannel.shared.preciseFindableDevices.enumerated() {

            if SharedData.getDevices().contains(where: {$0.uniqueId == String(scannedDevice!.bleUniqueID)}) {
                // device already paired, no need to show in scanned devices.

            } else {
                let device = ScannedDeviceView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))

                if let bleUniqueID = scannedDevice?.bleUniqueID {
                    device.numberLabel.text = String(bleUniqueID)
                    device.tag = bleUniqueID
                } else {
                    device.numberLabel.text = "unknown"
                }

                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                device.addGestureRecognizer(tapGesture)

                circularLayout.addCircularView(device)
            }
        }

        sheetView.addSubview(circularLayout)

    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        if let deviceView = gesture.view as? ScannedDeviceView {
               let selectedDevice = deviceView.tag
               scannedDeviceTapped(selectedDeviceId: selectedDevice)
           }
    }

    func scannedDeviceTapped(selectedDeviceId: Int) {
        let selectedDevice = BLEDataCommunicationChannel.shared.getDeviceFromUniqueID(selectedDeviceId)

        guard let uniqueId = selectedDevice?.bleUniqueID else {
            return
        }
        let vc = AddEditDeviceViewController(uniqueId: String(uniqueId))

        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func updateView() {
        circularLayout.removeFromSuperview()
        // Add the updated circular views based on the new array values
        addCircularView()
    }

}
