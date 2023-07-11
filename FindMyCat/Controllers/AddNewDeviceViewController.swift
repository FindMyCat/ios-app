//
//  AddDeviceViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/9/23.
//

import Foundation
import UIKit
import FittedSheets

class AddNewDeviceViewController: UIViewController {

    let sheetView = UIView()
    let scanningLabel = UILabel()

    override func viewDidLoad() {

        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

    }

    override func viewWillAppear(_ animated: Bool) {
        addSheet()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sheetView.addGestureRecognizer(panGesture)

        addScanningView()

        addScanningLabel()
    }

    func addSheet() {
        view.addSubview(sheetView)

        sheetView.backgroundColor = .white

        sheetView.layer.cornerRadius = 48

        sheetView.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 500)

        NSLayoutConstraint.activate([
            sheetView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10),
            sheetView.heightAnchor.constraint(equalToConstant: 500),
            sheetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomConstraint
        ])

        view.layoutIfNeeded()

        // Animate the slide-in effect
        bottomConstraint.constant = -5
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func addScanningView() {

        // Create the scanning view
        let scanningAnimationView = ScanningAnimationView(frame: CGRect(x: 0, y: 0, width: sheetView.frame.width, height: sheetView.frame.height))

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
            scanningLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 12)
        ])
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            if translation.y > 0 || translation.y < 0 {
                sheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            if translation.y >= 100 {
                UIView.animate(withDuration: 0.2) {
                    self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
                }
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.sheetView.transform = .identity
                }
            }
        default:
            break
        }
    }

}
