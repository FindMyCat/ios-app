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
    func light()
    func togglePingOrLostMode()
    func toggleAlertMode()
}

// What the alert button does on tap; long-press switches it, like Ping/Lost.
enum AlertMode {
    case sound
    case light
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
    let alertButton = Button()
    let pingOrlostModeButton = ButtonWithProgressBar()
    var currentMode: String = "ping" {
        didSet {
            updateUIForCurrentMode()
        }
    }
    var alertMode: AlertMode = .sound {
        didSet {
            updateAlertButton()
        }
    }
    var lightColor: LightColor = .white {
        didSet {
            updateAlertButton()
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
        configureAlertButton()
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

    private func configureAlertButton() {
        alertButton.configuration = UIButton.Configuration.tinted()
        alertButton.configuration?.buttonSize = buttonSize
        alertButton.configuration?.imagePadding = 10
        alertButton.configuration?.cornerStyle = .medium
        updateAlertButton()

        contentView.addSubview(alertButton)

        alertButton.translatesAutoresizingMaskIntoConstraints = false

        alertButton.addTarget(self, action: #selector(self.alertTapped), for: .touchUpInside)
        addHoldToSwitch(to: alertButton, action: #selector(self.alertLongPressed(_:)))

        NSLayoutConstraint.activate([
            alertButton.leadingAnchor.constraint(equalTo: findButton.trailingAnchor, constant: spacingBetweenExpandedStateButtons),
            alertButton.bottomAnchor.constraint(equalTo: findButton.bottomAnchor)
        ])
    }

    // Image goes on the configuration: setImage(_:for:) is dropped when the busy
    // spinner rewrites the configuration.
    private func updateAlertButton() {
        switch alertMode {
        case .sound:
            alertButton.configuration?.image = UIImage(systemName: "speaker.wave.2.fill")
            alertButton.tintColor = blueColor
            alertButton.accessibilityLabel = "Play sound"
        case .light:
            alertButton.configuration?.image = UIImage(systemName: "lightbulb.fill")
            alertButton.tintColor = lightColor == .white ? blueColor : lightColor.uiColor
            alertButton.accessibilityLabel = "Flash \(lightColor.name.lowercased()) light"
        }
    }

    @objc private func alertTapped() {
        switch alertMode {
        case .sound: delegate?.playSound()
        case .light: delegate?.light()
        }
    }

    @objc private func alertLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        alertMode = alertMode == .sound ? .light : .sound
        slapIn(alertButton) { [weak self] in self?.delegate?.toggleAlertMode() }
    }

    // MARK: - Hold to switch

    // Holding grows the button until the switch fires, then it springs back in, so the
    // user feels "keep holding... bam".
    private static let holdToSwitchSeconds: TimeInterval = 0.5
    private static let holdToSwitchScale: CGFloat = 1.25
    private let switchFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

    private func addHoldToSwitch(to button: UIButton, action: Selector) {
        let press = UILongPressGestureRecognizer(target: self, action: action)
        press.minimumPressDuration = Self.holdToSwitchSeconds
        button.addGestureRecognizer(press)
        button.addTarget(self, action: #selector(holdStarted(_:)), for: .touchDown)
    }

    // Letting go early is undone by Button's own isHighlighted animation.
    @objc private func holdStarted(_ button: UIButton) {
        switchFeedbackGenerator.prepare()
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: Self.holdToSwitchSeconds, delay: 0,
                       options: [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState]) {
            button.transform = CGAffineTransform(scaleX: Self.holdToSwitchScale, y: Self.holdToSwitchScale)
        }
    }

    // The delegate reloads the row, so it runs after the spring settles.
    private func slapIn(_ button: UIButton, then switched: @escaping () -> Void) {
        switchFeedbackGenerator.impactOccurred()
        guard !UIAccessibility.isReduceMotionEnabled else {
            button.transform = .identity
            switched()
            return
        }
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.35, initialSpringVelocity: 1,
                       options: [.beginFromCurrentState, .allowUserInteraction],
                       animations: { button.transform = .identity },
                       completion: { _ in switched() })
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

    /// Collar commands the hold-to-switch gesture cycles through, in order.
    static let commandModesInSwitchOrder = ["ping", "ping-wifi", "ping-gps", "ping-cell", "lost"]

    static func commandMode(after mode: String) -> String {
        let index = commandModesInSwitchOrder.firstIndex(of: mode) ?? 0
        return commandModesInSwitchOrder[(index + 1) % commandModesInSwitchOrder.count]
    }

    /// While lost mode runs the button stops it, whatever mode is selected.
    static func buttonTitle(forCommandMode mode: String, isLostModeOn: Bool) -> String {
        if isLostModeOn { return "Stop Lost" }
        let titles = ["ping": "Ping", "ping-wifi": "WiFi Ping", "ping-gps": "GPS Ping", "ping-cell": "Cell Ping", "lost": "Lost"]
        return titles[mode] ?? mode.capitalized
    }

    var isLostModeOn = false {
        didSet {
            updateUIForCurrentMode()
        }
    }

    func updateUIForCurrentMode() {
        let isLostStyle = isLostModeOn || currentMode == "lost"
        pingOrlostModeButton.tintColor = isLostStyle ? redColor : UIColor.systemOrange
        if pingOrlostModeButton.configuration?.showsActivityIndicator != true {
            pingOrlostModeButton.configuration?.title = Self.buttonTitle(forCommandMode: currentMode, isLostModeOn: isLostModeOn)
        }
    }

    private func configureLostModeButton() {
        pingOrlostModeButton.configuration = UIButton.Configuration.tinted()
        pingOrlostModeButton.configuration?.cornerStyle = .medium

        pingOrlostModeButton.layer.cornerRadius = 8.0
        pingOrlostModeButton.configuration?.buttonSize = buttonSize

        contentView.addSubview(pingOrlostModeButton)

        updateUIForCurrentMode()

        pingOrlostModeButton.translatesAutoresizingMaskIntoConstraints = false

        pingOrlostModeButton.addTarget(self, action: #selector(self.activateLostMode), for: .touchUpInside)
        // Added once here; adding it per cellForRowAt stacked recognizers on reused cells.
        addHoldToSwitch(to: pingOrlostModeButton, action: #selector(self.pingLongPressed(_:)))

        NSLayoutConstraint.activate([
            pingOrlostModeButton.leadingAnchor.constraint(equalTo: alertButton.trailingAnchor, constant: spacingBetweenExpandedStateButtons),
            pingOrlostModeButton.bottomAnchor.constraint(equalTo: alertButton.bottomAnchor)
        ])
    }

    @objc private func activateLostMode() {
        delegate?.activateLostMode(currentMode: currentMode)
    }

    @objc private func pingLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        currentMode = Self.commandMode(after: currentMode)
        slapIn(pingOrlostModeButton) { [weak self] in self?.delegate?.togglePingOrLostMode() }
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
