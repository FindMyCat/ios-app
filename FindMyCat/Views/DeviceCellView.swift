//
//  DeviceCellView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/29/23.
//

import UIKit

import UIKit


class DeviceCellView: UITableViewCell {
    let nameLabel = UILabel()
    let batteryLabel = UILabel()
    let batteryIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setBatteryPercentage(percentage: Double) {
        batteryLabel.text = "\(Int(percentage))"
        let batteryIconImageConfig = UIImage.SymbolConfiguration(pointSize: 25)
        let battPercentageRounded = roundBatteryPercentage(Int(percentage))
        batteryIcon.image = UIImage(systemName: "battery.\(battPercentageRounded)", withConfiguration: batteryIconImageConfig)
    
    }
    private func configureSubviews() {
        // Configure the labels
        nameLabel.textAlignment = .left
        batteryLabel.textAlignment = .right
        batteryLabel.font = UIFont.boldSystemFont(ofSize: 8)
        batteryLabel.textColor = .black
        
        // Set the battery icon and percentage

        let batteryIconImageConfig = UIImage.SymbolConfiguration(pointSize: 25)
        if let batteryLabelText = batteryLabel.text, let percentage = Int(batteryLabelText) {
            let battPercentageRounded = roundBatteryPercentage(percentage)
            batteryIcon.image = UIImage(systemName: "battery.\(battPercentageRounded)", withConfiguration: batteryIconImageConfig)
        } else {
            batteryIcon.image = UIImage(systemName: "battery.100", withConfiguration: batteryIconImageConfig)
        }
       
        
        batteryIcon.tintColor = .black
        
        // Add labels to the cell's contentView
        contentView.addSubview(nameLabel)
        contentView.addSubview(batteryIcon)
//        contentView.addSubview(batteryLabel)
        
        
        // Add constraints for the labels
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        batteryLabel.translatesAutoresizingMaskIntoConstraints = false
        batteryIcon.translatesAutoresizingMaskIntoConstraints =  false
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            batteryIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            batteryIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
//
//            batteryLabel.centerYAnchor.constraint(equalTo: batteryIcon.centerYAnchor),
//            batteryLabel.centerXAnchor.constraint(equalTo: batteryIcon.centerXAnchor, constant: -2)
        ])
    }

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
