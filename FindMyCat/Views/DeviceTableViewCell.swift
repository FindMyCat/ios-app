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

protocol DeviceCellDelegate: AnyObject {
    func launchPreciseFindScreen()
    func activateLostMode(currentMode: String)
    func playSound()
}

class ButtonWithProgressBar: UIButton {

    let buttonWidthDuringPinging = 115.0
    private var buttonWidthDuringPingingConstraint: NSLayoutConstraint?

    func setPingInFlight(since sentAt: Date?, idleTitle: String, edrxSeconds: Double? = nil) {
        guard let sentAt = sentAt else {
            buttonWidthDuringPingingConstraint?.isActive = false
            configuration?.showsActivityIndicator = false
            configuration?.title = idleTitle
            isEnabled = true
            return
        }

        if buttonWidthDuringPingingConstraint == nil {
            buttonWidthDuringPingingConstraint = widthAnchor.constraint(equalToConstant: buttonWidthDuringPinging)
        }
        buttonWidthDuringPingingConstraint?.isActive = true

        configuration?.showsActivityIndicator = true
        configuration?.imagePadding = 8
        configuration?.title = ButtonWithProgressBar.pingTitle(since: sentAt, edrxSeconds: edrxSeconds)
        isEnabled = false
        layoutIfNeeded()
    }

    /// Counts down to the collar's worst-case paging window while one is due,
    /// then counts up how long the ping has been out.
    static func pingTitle(since sentAt: Date, edrxSeconds: Double?) -> String {
        let elapsed = Int(Date().timeIntervalSince(sentAt))

        if let edrxSeconds, elapsed < Int(edrxSeconds.rounded(.up)) {
            let remaining = Int(edrxSeconds.rounded(.up)) - elapsed
            return String(format: "~%d:%02d", remaining / 60, remaining % 60)
        }

        return String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

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

class DeviceTableViewCell: UITableViewCell {

    // Always visible views
    let deviceNameLabel = UILabel()
    let deviceAddressLabel = UILabel()
    let emojiLabel = UILabel()
    let dotSeparatorView = UIView()
    let lastSeenLabel = UILabel()
    let batteryIcon = BatteryView()

    // Expanded state views
    let findButton = Button()
    let soundButton = Button()
    let pingOrlostModeButton = ButtonWithProgressBar()
    var currentMode: String = "ping" {
        didSet {
            updateUIForCurrentMode()
        }
    }

    // Colors
    let grayColor = CGColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
    let blueColor = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
    let redColor = UIColor(red: 255/255, green: 10/255, blue: 10/255, alpha: 1)

    // Constants
    let buttonSize = UIButton.Configuration.Size.large
    let profilePictureSize = 40.0
    let spacingBetweenExpandedStateButtons = 12.0

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

    // MARK: - Configurations of Subviews

    private func configureSubviews() {

        contentView.clipsToBounds = true

        configureProfilePictureEmojiLabel()
        configureDeviceNameLabel()
        configureDeviceAddressLabel()
        configureBatteryIcon()
        configureFindButton()
        configurePlaySoundButton()
        configureLostModeButton()

        configureLastSeenLabel()

    }

    private func configureProfilePictureEmojiLabel() {
        contentView.addSubview(emojiLabel)
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
        deviceAddressLabel.textColor = .systemGray2

        deviceAddressLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            deviceAddressLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            deviceAddressLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 5)
        ])

    }

    private func configureLastSeenLabel() {

        // Dot separator
        contentView.addSubview(dotSeparatorView)

        let dotDiameter = CGFloat(3)

        dotSeparatorView.backgroundColor = .systemGray2

        dotSeparatorView.translatesAutoresizingMaskIntoConstraints = false

        dotSeparatorView.layer.cornerRadius = dotDiameter / 2

        NSLayoutConstraint.activate([
            dotSeparatorView.centerYAnchor.constraint(equalTo: deviceAddressLabel.centerYAnchor),
            dotSeparatorView.leadingAnchor.constraint(equalTo: deviceAddressLabel.trailingAnchor, constant: 5),
            dotSeparatorView.widthAnchor.constraint(equalToConstant: dotDiameter),
            dotSeparatorView.heightAnchor.constraint(equalToConstant: dotDiameter)
        ])

        // Last seen label

        contentView.addSubview(lastSeenLabel)

        lastSeenLabel.font = UIFont.systemFont(ofSize: 13)
        lastSeenLabel.textColor = .systemGray2

        lastSeenLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            lastSeenLabel.leadingAnchor.constraint(equalTo: dotSeparatorView.trailingAnchor, constant: 5),
            lastSeenLabel.centerYAnchor.constraint(equalTo: dotSeparatorView.centerYAnchor)
        ])

    }

    private func configureBatteryIcon() {
        batteryIcon.translatesAutoresizingMaskIntoConstraints =  false
        contentView.addSubview(batteryIcon)

        NSLayoutConstraint.activate([
            batteryIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            batteryIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 23)])
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

        soundButton.addTarget(self, action: #selector(self.playSoundTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            soundButton.leadingAnchor.constraint(equalTo: findButton.trailingAnchor, constant: spacingBetweenExpandedStateButtons),
            soundButton.bottomAnchor.constraint(equalTo: findButton.bottomAnchor)
        ])
    }

    @objc private func playSoundTapped() {
        delegate?.playSound()
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

    func updateUIForCurrentMode() {
        if currentMode == "ping" {
            pingOrlostModeButton.tintColor = UIColor.systemOrange
        } else {
            // Red color for Lost Mode
            pingOrlostModeButton.tintColor = redColor
        }
        if pingOrlostModeButton.configuration?.showsActivityIndicator != true {
            pingOrlostModeButton.configuration?.title = currentMode.capitalized
        }
    }

    private func configureLostModeButton() {
        if currentMode == "ping" {
            pingOrlostModeButton.tintColor = UIColor.systemOrange
        } else {
            // Red color for Lost Mode
            pingOrlostModeButton.tintColor = redColor
        }

        pingOrlostModeButton.configuration = UIButton.Configuration.tinted()
        pingOrlostModeButton.configuration?.cornerStyle = .medium

        pingOrlostModeButton.layer.cornerRadius = 8.0
        pingOrlostModeButton.configuration?.buttonSize = buttonSize

        contentView.addSubview(pingOrlostModeButton)

        pingOrlostModeButton.configuration?.title = currentMode.capitalized

        pingOrlostModeButton.translatesAutoresizingMaskIntoConstraints = false

        pingOrlostModeButton.addTarget(self, action: #selector(self.activateLostMode), for: .touchUpInside)

        NSLayoutConstraint.activate([
            pingOrlostModeButton.leadingAnchor.constraint(equalTo: soundButton.trailingAnchor, constant: spacingBetweenExpandedStateButtons),
            pingOrlostModeButton.bottomAnchor.constraint(equalTo: soundButton.bottomAnchor)
        ])
    }

    @objc private func activateLostMode() {
        delegate?.activateLostMode(currentMode: currentMode)
    }
    // MARK: - Public Methods

    func setBatteryPercentage(percentage: Double) {
        batteryIcon.percentage = percentage
    }
}

/// iOS 17 style battery: the fill reaches the body's edges, with the number
/// drawn over it.
class BatteryView: UIView {
    var percentage: Double = 0 {
        didSet { setNeedsDisplay() }
    }

    private let bodySize = CGSize(width: 30, height: 16)
    private let nubSize = CGSize(width: 2, height: 6)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: bodySize.width + 1 + nubSize.width, height: bodySize.height)
    }

    override func draw(_ rect: CGRect) {
        let level = min(max(percentage, 0), 100) / 100
        let body = UIBezierPath(roundedRect: CGRect(origin: .zero, size: bodySize), cornerRadius: 4.5)
        let nub = UIBezierPath(
            roundedRect: CGRect(x: bodySize.width + 1, y: (bodySize.height - nubSize.height) / 2,
                                width: nubSize.width, height: nubSize.height),
            byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 1, height: 1))

        UIColor.systemGray3.setFill()
        body.fill()
        nub.fill()

        body.addClip()
        (percentage <= 20 ? UIColor.systemRed : UIColor.systemGreen).setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: bodySize.width * level, height: bodySize.height))

        let text = "\(Int(percentage.rounded()))" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.darkGray
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: (bodySize.width - size.width) / 2, y: (bodySize.height - size.height) / 2),
                  withAttributes: attributes)
    }
}
