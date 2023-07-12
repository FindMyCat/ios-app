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
    let closeButton = UIButton()
    override func viewDidLoad() {

        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

    }

    override func viewWillAppear(_ animated: Bool) {
        addSheet()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sheetView.addGestureRecognizer(panGesture)

        addScanningView()

        addScanningLabel()

        addCloseButton()

        addCircularView()
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
            scanningLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 24)
        ])
    }

    func addCloseButton() {
        sheetView.addSubview(closeButton)

        var configuration = UIButton.Configuration.tinted()
        configuration.cornerStyle = .capsule

        closeButton.configuration = configuration

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: imageConfig), for: .normal)

        closeButton.tintColor = .gray

        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            closeButton.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 24),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
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

    @objc func dismissSelf() {
        // make sheet animate out of frame and then dismiss
        UIView.animate(withDuration: 0.2) {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        }
        dismiss(animated: true)
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            if translation.y > 0 || translation.y < 0 {
                sheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            if translation.y >= 300 {
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
