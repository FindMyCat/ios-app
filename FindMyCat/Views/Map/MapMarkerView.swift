//
//  MapMarkerView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/29/23.
//

import UIKit
import Foundation

class CustomAnnotationView: UIView {

    private let avatarEmojiLabel = UILabel()

    // MARK: - View Lifecycles

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupShadow()
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
        setupShadow()
        setupSubviews()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let pinHeight: CGFloat = 12.0
        // Set the circle color and size
        let fillColor = UIColor.init(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
        let circleRadius: CGFloat = min(bounds.width - (pinHeight), bounds.height - (pinHeight)) / 2

        // Calculate the center of the circle
        let circleCenter = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        fillColor.setFill()
        context.setBlendMode(.normal)
        context.fillEllipse(in: CGRect(x: circleCenter.x - circleRadius,
                                       y: circleCenter.y - circleRadius,
                                       width: circleRadius * 2.0,
                                       height: circleRadius * 2.0))

        // Calculate the notch position
        let notchWidth: CGFloat = 15.0
        let notchPosition = CGPoint(x: bounds.width / 2.0 - notchWidth / 2.0, y: bounds.height / 2 + circleRadius - 5 )

        // Draw the pin notch first
        let notchPath = UIBezierPath()
        notchPath.move(to: notchPosition)
        notchPath.addLine(to: CGPoint(x: notchPosition.x + notchWidth, y: notchPosition.y))
        notchPath.addLine(to: CGPoint(x: notchPosition.x + notchWidth / 2.0, y: notchPosition.y + pinHeight))
        notchPath.close()

        fillColor.setFill() // Set notch color to yellow
        notchPath.fill()

        // Draw the circle on top of the pin notch
        context.saveGState()

        context.restoreGState()
    }

    // MARK: - Configuration of all subviews

    private func setupShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }

    private func setupSubviews() {
        addSubview(avatarEmojiLabel)
     }

    // MARK: - Public methods

    public func setEmoji(emoji: String) {
        avatarEmojiLabel.text = emoji
        avatarEmojiLabel.textAlignment = .center
        avatarEmojiLabel.font = .systemFont(ofSize: 30)
        avatarEmojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
              avatarEmojiLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
              avatarEmojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
          ])
    }

}
