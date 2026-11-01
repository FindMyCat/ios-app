//
//  UWBMessages.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/6/23.
//

import UIKit

// An example messaging protocol for communications between the app and the
// accessory. In your app, modify or extend this enumeration to your app's
// user experience and conform the accessory accordingly.
enum MessageId: UInt8 {
    // Messages from the accessory.
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3

    // Messages to the accessory.
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC

    // User defined/notification messages
    case getReserved = 0x20
    case setReserved = 0x21

    case iOSNotify = 0x2F

    case playSound = 0x30

    // Payload: one LightColor byte.
    case light = 0x31
}

// Collar LED mask: bit0 blue, bit1 green, bit2 red. The PMIC LEDs are on/off
// only, so these seven are the only colors the collar can show.
enum LightColor: UInt8, CaseIterable {
    case white = 0x7
    case red = 0x4
    case yellow = 0x6
    case green = 0x2
    case aqua = 0x3
    case blue = 0x1
    case purple = 0x5

    var name: String {
        switch self {
        case .white: return "White"
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .aqua: return "Aqua"
        case .blue: return "Blue"
        case .purple: return "Purple"
        }
    }

    var uiColor: UIColor {
        switch self {
        case .white: return .white
        case .red: return .systemRed
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .aqua: return .systemCyan
        case .blue: return .systemBlue
        case .purple: return .systemPurple
        }
    }
}
