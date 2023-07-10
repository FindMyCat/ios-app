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

class EmojiTextField: UITextField {

    // required for iOS 13
    override var textInputContextIdentifier: String? { "" } // return non-nil to show the Emoji keyboard ¯\_(ツ)_/¯

    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
    }
}

protocol DeviceCellDelegate: AnyObject {
    func launchPreciseFindScreen()
}

class DeviceCellView: UITableViewCell {

    // Always visible views
    let deviceNameLabel = UILabel()
    let deviceAddressLabel = UILabel()
    let emojiLabel = UILabel()
    let dotSeparator = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    let lastSeen = UILabel()
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
    let profilePictureSize = 40.0

    // Delegate
    weak var delegate: DeviceCellDelegate?

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        // invoke superclass implementation
        super.prepareForReuse()

        // reset labels and icons
        self.batteryIcon.image = nil
        self.deviceAddressLabel.text = nil
    }

    // MARK: - Configurations of Subviews

    private func configureSubviews() {

        contentView.clipsToBounds = true

        configureProfilePictureEmojiLabel()
        configureDeviceNameLabel()
        configureDeviceAddressLabel()
        configureBatteryIcon()
//        configureBatteryPercentageLabel()
        configureFindButton()
        configurePlaySoundButton()

    }

    private func configureProfilePictureEmojiLabel() {
        contentView.addSubview(emojiLabel)
        emojiLabel.text = "💖"
        emojiLabel.textAlignment = .center
        emojiLabel.font = UIFont.systemFont(ofSize: profilePictureSize - 20)
        emojiLabel.backgroundColor = UIColor.init(white: 0.96, alpha: 1)
        emojiLabel.frame = CGRect(x: 0, y: 0, width: profilePictureSize, height: profilePictureSize)

        emojiLabel.layer.cornerRadius = emojiLabel.bounds.width / 2
        emojiLabel.layer.borderColor = UIColor.systemGray4.cgColor
        emojiLabel.layer.borderWidth = 2
        emojiLabel.clipsToBounds = true

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            emojiLabel.widthAnchor.constraint(equalToConstant: profilePictureSize),
            emojiLabel.heightAnchor.constraint(equalToConstant: profilePictureSize)
        ])
    }

    private func configureDeviceNameLabel() {
        deviceNameLabel.textAlignment = .left
        deviceNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        contentView.addSubview(deviceNameLabel)

        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            deviceNameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 8),
            deviceNameLabel.topAnchor.constraint(equalTo: emojiLabel.topAnchor, constant: 1)
        ])

    }

    private func configureDeviceAddressLabel() {
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
        soundButton.configuration?.cornerStyle = .medium
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
        findButton.configuration?.cornerStyle = .medium

        findButton.layer.borderColor = grayColor
        findButton.layer.borderWidth = 1
        findButton.layer.cornerRadius = 8.0
        findButton.configuration?.buttonSize = buttonSize
        findButton.configuration?.imagePadding = 10

        findButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)

        contentView.addSubview(findButton)

        findButton.setTitle("Find", for: .normal)
        findButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 200)

        findButton.translatesAutoresizingMaskIntoConstraints = false

        findButton.addTarget(self, action: #selector(self.preciseFind), for: .touchUpInside)

        NSLayoutConstraint.activate([
            findButton.leadingAnchor.constraint(equalTo: deviceAddressLabel.leadingAnchor),
            findButton.centerYAnchor.constraint(equalTo: deviceAddressLabel.centerYAnchor, constant: 60)])

    }

    @objc private func preciseFind() {
        delegate?.launchPreciseFindScreen()
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
