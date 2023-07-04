//
//  DeviceCellView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/29/23.
//

import UIKit

class Button: UIButton {
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    override var isHighlighted: Bool {
          didSet {
              UIView.animate(withDuration: 0.15) {
                  self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
                  self.alpha = self.isHighlighted ? 0.8 : 1.0
              }
              feedbackGenerator.prepare()

              feedbackGenerator.impactOccurred(intensity: 1)
          }
      }
}

class DeviceCellView: UITableViewCell {

    // Always visible views
    let deviceNameLabel = UILabel()
    let deviceAddressLabel = UILabel()

    let batteryIcon = UIImageView()

    // Expanded state views
    let expandedStateBatteryPercentage = UILabel()
    let findButton = Button()
    let soundButton = Button()

    // Colors
    let grayColor = CGColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
    let blueColor = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)

    // Constants
    let buttonSize = UIButton.Configuration.Size.large

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configurations of Subviews

    private func configureSubviews() {

        contentView.clipsToBounds = true

        configureDeviceNameLabel()
        configureDeviceAddressLabel()
        configureBatteryIcon()
        configureBatteryPercentageLabel()
        configureFindButton()
        configurePlaySoundButton()
    }

    private func configureDeviceNameLabel() {
        deviceNameLabel.textAlignment = .left
        deviceNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        contentView.addSubview(deviceNameLabel)

        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            deviceNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deviceNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        ])

    }

    private func configureDeviceAddressLabel() {
        deviceAddressLabel.text = "Home"
        contentView.addSubview(deviceAddressLabel)
        deviceAddressLabel.font = UIFont.systemFont(ofSize: 13)
        deviceAddressLabel.alpha = 0.3

        deviceAddressLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            deviceAddressLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            deviceAddressLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 5)
        ])

    }

    private func configureBatteryIcon() {
        batteryIcon.tintColor = .black
        batteryIcon.translatesAutoresizingMaskIntoConstraints =  false
        contentView.addSubview(batteryIcon)

        NSLayoutConstraint.activate([
            batteryIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            batteryIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 23)])
    }

    private func configureBatteryPercentageLabel() {
        contentView.addSubview(expandedStateBatteryPercentage)

        expandedStateBatteryPercentage.font = UIFont.systemFont(ofSize: 13)
        expandedStateBatteryPercentage.alpha = 0.3

        expandedStateBatteryPercentage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            expandedStateBatteryPercentage.centerXAnchor.constraint(equalTo: batteryIcon.centerXAnchor),
            expandedStateBatteryPercentage.centerYAnchor.constraint(equalTo: batteryIcon.centerYAnchor, constant: 40)

        ])
    }

    private func configurePlaySoundButton() {
        soundButton.tintColor = blueColor
        soundButton.configuration = UIButton.Configuration.tinted()
        soundButton.configuration?.buttonSize = buttonSize
        soundButton.configuration?.imagePadding = 10
        soundButton.configuration?.cornerStyle = .large
        soundButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)

        contentView.addSubview(soundButton)

        soundButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            soundButton.leadingAnchor.constraint(equalTo: findButton.trailingAnchor, constant: 16),
            soundButton.bottomAnchor.constraint(equalTo: findButton.bottomAnchor)
        ])
    }

    private func configureFindButton() {
        findButton.tintColor = UIColor(cgColor: grayColor)

        findButton.configuration = UIButton.Configuration.plain()
        findButton.configuration?.cornerStyle = .large

        findButton.layer.borderColor = grayColor
        findButton.layer.borderWidth = 1
        findButton.layer.cornerRadius = 14.0
        findButton.configuration?.buttonSize = buttonSize
        findButton.configuration?.imagePadding = 10

        findButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)

        contentView.addSubview(findButton)

        findButton.setTitle("Find", for: .normal)
        findButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 200)

        findButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            findButton.leadingAnchor.constraint(equalTo: deviceAddressLabel.leadingAnchor),
            findButton.centerYAnchor.constraint(equalTo: deviceAddressLabel.centerYAnchor, constant: 60)])

    }

    // MARK: - Public Methods

    func setBatteryPercentage(percentage: Double) {
        expandedStateBatteryPercentage.text = "\(Int(percentage))"
        let batteryIconImageConfig = UIImage.SymbolConfiguration(pointSize: 20)
        let battPercentageRounded = roundBatteryPercentage(Int(percentage))
        batteryIcon.image = UIImage(systemName: "battery.\(battPercentageRounded)", withConfiguration: batteryIconImageConfig)
    }

    // MARK: - Private Methods

   private func roundBatteryPercentage(_ percentage: Int) -> Int {
        let roundedValue: Int
        switch percentage {
        case 0...12:
            roundedValue = 0
        case 13...37:
            roundedValue = 25
        case 38...62:
            roundedValue = 50
        case 63...87:
            roundedValue = 75
        default:
            roundedValue = 100
        }
        return roundedValue
    }
}
