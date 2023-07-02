//
//  DeviceCellView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/29/23.
//

import UIKit

class DeviceCellView: UITableViewCell {
    let nameLabel = UILabel()
    let batteryIcon = UIImageView()

    // Expanded state views
    let expandedStateBatteryLabel = UILabel()

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
        // Configure the normal views (always visible regardless of expansion state)
        nameLabel.textAlignment = .left
        batteryIcon.tintColor = .black

        // Add labels to the cell's contentView
        contentView.addSubview(nameLabel)
        contentView.addSubview(batteryIcon)

        // Add constraints for the labels
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        expandedStateBatteryLabel.translatesAutoresizingMaskIntoConstraints = false
        batteryIcon.translatesAutoresizingMaskIntoConstraints =  false

        // Expanded state views
        expandedStateBatteryLabel.textAlignment = .right
        expandedStateBatteryLabel.font = UIFont.boldSystemFont(ofSize: 8)
        expandedStateBatteryLabel.textColor = .black

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),

            batteryIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            batteryIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])

    }

    // MARK: - Public Methods

    func setBatteryPercentage(percentage: Double) {
        expandedStateBatteryLabel.text = "\(Int(percentage))"
        let batteryIconImageConfig = UIImage.SymbolConfiguration(pointSize: 20)
        let battPercentageRounded = roundBatteryPercentage(Int(percentage))
        batteryIcon.image = UIImage(systemName: "battery.\(battPercentageRounded)", withConfiguration: batteryIconImageConfig)
    }

    func enableExpandedState() {
            contentView.addSubview(expandedStateBatteryLabel)

        NSLayoutConstraint.activate([
            // Expanded state constraints
            expandedStateBatteryLabel.centerYAnchor.constraint(equalTo: batteryIcon.centerYAnchor),
            expandedStateBatteryLabel.centerXAnchor.constraint(equalTo: batteryIcon.centerXAnchor, constant: -2)
        ])
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
