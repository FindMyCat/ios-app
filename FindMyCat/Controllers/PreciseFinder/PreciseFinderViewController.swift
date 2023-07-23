//
//  PreciseViewController.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/5/23.
//

import Foundation
import UIKit
import AVFoundation
import ARKit
import RealityKit
import NearbyInteraction
import os.log

class PreciseFinderViewContoller: UIViewController {

    // MARK: - Device to connect to
    private var deviceDisplayName: String
    internal var deviceUniqueBLEId: Int

    // MARK: - Simple views to show information
    internal let arrowImgView = UIImageView(image: UIImage(systemName: "arrow.up"))
    internal let distanceLabel = UILabel()

    private let deviceNameLabel = UILabel()
    private let cancelButton = UIButton()
    private let soundButton = UIButton()
    private let circle = UIView()

    internal let searchingLabel = UILabel()

    let viewLayerColor = UIColor.white

    // MARK: AR camera layer for blurring
    internal var arView: ARSCNView!
    let arConfig = ARWorldTrackingConfiguration()

    // MARK: UWB
    // Dictionary to associate each NI Session to the qorvoDevice using the uniqueID
    internal var referenceDict = [Int: NISession]()
    // A mapping from a discovery token to a name.
    internal var accessoryDiscoveryTokenToNameMap = [NIDiscoveryToken: String]()
    internal var accessoryConfig: NINearbyAccessoryConfiguration?
    internal var NIAlgorithmHasConverged = false

    // MARK: - Util managers
    let uwbUtilManager = UWBUtils()

    // MARK: - Extras
    let logger = Logger(subsystem: "ViewControllers", category: String(describing: PreciseFinderViewContoller.self))

    // MARK: - Initializers

    init(deviceDisplayName: String, deviceUniqueBLEId: Int) {
        self.deviceDisplayName = deviceDisplayName
        self.deviceUniqueBLEId = deviceUniqueBLEId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycles
    override func viewDidLoad() {
        view.backgroundColor = .white
        setupSubviews()

        configureDataChannel()
    }

    deinit {
        // Remove the observer when the view controller is deallocated
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willResignActiveNotification,
                                                  object: nil)

        // Pause the ARSession before it gets deallocated
        pauseARSession()
    }

    // MARK: - Setup subviews

    private func setupSubviews() {
        setupCameraBlurLayer()
        setupArrowImage()
        setupDeviceName()
        setupControlButtons()
        setupDistanceLabel()
        setupCircleAroundArrow()
        addSearchingLabel()
    }

    func addSearchingLabel() {
        view.addSubview(searchingLabel)
        searchingLabel.font = .boldSystemFont(ofSize: 20)
        searchingLabel.text = "Searching..."
        searchingLabel.textColor = viewLayerColor

        searchingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        searchingLabel.alpha = 0.8

        let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateAlpha), userInfo: nil, repeats: true)
        timer.fire()

    }

    @objc func updateAlpha() {
        UIView.animate(withDuration: 0.5, animations: {
                   self.searchingLabel.alpha = self.searchingLabel.alpha == 1.0 ? 0.3 : 1.0
               })
    }

    func setupArrowImage() {
        view.addSubview(arrowImgView)

        arrowImgView.tintColor = viewLayerColor

        arrowImgView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = arrowImgView.widthAnchor.constraint(equalToConstant: 200)
        let heightConstraint = arrowImgView.heightAnchor.constraint(equalToConstant: 200)

        NSLayoutConstraint.activate([
            arrowImgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowImgView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heightConstraint,
            widthConstraint
        ])
        arrowImgView.isHidden = true
    }

    func setupCameraBlurLayer() {

        arView = ARSCNView(frame: view.bounds)
        view.addSubview(arView)

        // Set/start AR Session to provide camera assistance to new NI Sessions
        arConfig.worldAlignment = .gravity
        arConfig.isCollaborationEnabled = false
        arConfig.userFaceTrackingEnabled = false
        arConfig.initialWorldMap = nil
        arView.session = ARSession()
        arView.session.delegate = self
        arView.session.run(arConfig)

        // Apply blur effect to the background view
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        self.view.addSubview(blurEffectView)

        // Add observer for pausing of AR session.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pauseARSession),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }

    func setupDeviceName() {
        view.addSubview(deviceNameLabel)

        deviceNameLabel.text = deviceDisplayName
        deviceNameLabel.font = UIFont.boldSystemFont(ofSize: 40)
        deviceNameLabel.textColor = viewLayerColor

        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deviceNameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            deviceNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30)
        ])
    }

    func setupControlButtons() {
        setupCancelButton()
        setupSoundButton()
    }

    func setupCancelButton() {
        view.addSubview(cancelButton)

        cancelButton.configuration = UIButton.Configuration.tinted()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.configuration?.cornerStyle = .capsule
        cancelButton.configuration?.buttonSize = .large

        cancelButton.tintColor = viewLayerColor
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30)
        ])

        // Add a target to the cancelButton
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)

    }

    func setupSoundButton() {
        view.addSubview(soundButton)

        soundButton.configuration = UIButton.Configuration.tinted()
        soundButton.setTitle("Sound", for: .normal)
        soundButton.configuration?.cornerStyle = .capsule
        soundButton.configuration?.buttonSize = .large

        soundButton.tintColor = viewLayerColor
        soundButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            soundButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            soundButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }

    func setupDistanceLabel() {
        view.addSubview(distanceLabel)

        //        distanceLabel.text = "10 ft"
        distanceLabel.font = UIFont.boldSystemFont(ofSize: 50)
        distanceLabel.textColor = viewLayerColor

        distanceLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            distanceLabel.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -20),
            distanceLabel.leadingAnchor.constraint(equalTo: cancelButton.leadingAnchor)
        ])

    }

    func setupCircleAroundArrow() {
        let circleSize = CGFloat(300)
        circle.layer.cornerRadius = circleSize / 2
        circle.layer.borderWidth = 4.0
        circle.layer.borderColor = viewLayerColor.cgColor
        circle.alpha = 0.4

        view.addSubview(circle)

        circle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: circleSize),
            circle.heightAnchor.constraint(equalToConstant: circleSize)
        ])
    }

    // MARK: - Objc Helper methods
    @objc func pauseARSession() {
        // Pause the ARSession if it is running
        arView.session.pause()
    }

    @objc private func cancelButtonPressed() {
        // cleanup -- stop the data channel and disconnect from Device.
        deinitDataCommunicationChannel()
        disconnectFromAccessory(deviceUniqueBLEId)
        dismiss(animated: true, completion: nil)
    }
}
