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

    override func viewDidLoad() {

        navigationController?.pushViewController(AddEditDeviceViewController(), animated: false)

        addSheet()

        addScanningView()

        addScanningLabel()

        addCircularView()

    }

    func addSheet() {
        view.addSubview(sheetView)

        sheetView.showInView(view, height: 500)

    }

    func addScanningView() {

        // Create the scanning view
        let scanningAnimationView = ScanningAnimationView(frame: CGRect(x: 0, y: 70, width: sheetView.frame.width, height: sheetView.frame.height))

        sheetView.addSubview(scanningAnimationView)

        scanningAnimationView.startAnimation()

        scanningAnimationView.translatesAutoresizingMaskIntoConstraints = false

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
        let circularLayout = CircularViewLayout(frame: CGRect(x: 0, y: 70, width: sheetView.bounds.width, height: sheetView.bounds.height - 70))
        circularLayout.backgroundColor = .clear

        let circleSize = CGFloat(80)
        let view1 = UIView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))
        view1.translatesAutoresizingMaskIntoConstraints = false
        view1.widthAnchor.constraint(equalToConstant: circleSize).isActive = true
        view1.heightAnchor.constraint(equalToConstant: circleSize).isActive = true
        view1.layer.cornerRadius = circleSize / 2.0
        view1.backgroundColor = .red

        let view2 = UIView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))
        view2.translatesAutoresizingMaskIntoConstraints = false
        view2.widthAnchor.constraint(equalToConstant: circleSize).isActive = true
        view2.heightAnchor.constraint(equalToConstant: circleSize).isActive = true
        view2.layer.cornerRadius = circleSize / 2.0
        view2.backgroundColor = .green

        let view3 = UIView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))
        view3.translatesAutoresizingMaskIntoConstraints = false
        view3.widthAnchor.constraint(equalToConstant: circleSize).isActive = true
        view3.heightAnchor.constraint(equalToConstant: circleSize).isActive = true
        view3.layer.cornerRadius = circleSize / 2
        view3.backgroundColor = .blue

        circularLayout.addCircularView(view1)
        circularLayout.addCircularView(view2)
//        circularLayout.addCircularView(view3)

        sheetView.addSubview(circularLayout)
    }

}
