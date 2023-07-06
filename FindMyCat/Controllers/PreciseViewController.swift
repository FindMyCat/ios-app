//
//  PreciseViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/5/23.
//

import Foundation
import UIKit
import AVFoundation

class PreciseViewContoller: UIViewController {

    private let arrowImgView = UIImageView(image: UIImage(systemName: "arrow.up"))

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - View lifecycles
    override func viewDidLoad() {
        view.backgroundColor = .white
        setupSubviews()

    }

    // MARK: - Setup subviews

    private func setupSubviews() {
        setupCameraBlurLayer()
        setupArrowImage()
    }

    func setupArrowImage() {
        view.addSubview(arrowImgView)

        arrowImgView.tintColor = .white

        arrowImgView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = arrowImgView.widthAnchor.constraint(equalToConstant: 200)
        let heightConstraint = arrowImgView.heightAnchor.constraint(equalToConstant: 200)

        NSLayoutConstraint.activate([
            arrowImgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowImgView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heightConstraint,
            widthConstraint
        ])
    }

    func setupCameraBlurLayer() {

        // Create a new capture session
        let captureSession = AVCaptureSession()

        // Set up the capture device (in this case, the back camera)
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        do {
            // Create an AVCaptureDeviceInput with the capture device
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

            // Add the input to the capture session
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }

            // Perform UI-related tasks on the main thread
            self.captureSession = captureSession

            // Create a container view to hold the preview layer
            let previewContainerView = UIView(frame: self.view.bounds)
            previewContainerView.backgroundColor = .clear
            self.view.addSubview(previewContainerView)

            // Create an AVCaptureVideoPreviewLayer for previewing the camera feed
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = previewContainerView.bounds
            previewContainerView.layer.addSublayer(previewLayer)

            /* starting capture session in a background thread */
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }

            // Apply blur effect to the background view
            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.view.bounds
            self.view.addSubview(blurEffectView)

        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }
}
