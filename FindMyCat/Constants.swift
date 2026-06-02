//
//  Constants.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/29/23.
//

import Foundation

struct Constants {

    // Notifications
    static let DevicesUpdatedNotificationName = "DevicesUpdated"
    static let PositionsUpdatedNotificationName = "PositionsUpdated"
    static let PreciseFindableDevicesUpdatedNotificationName = "PreciseFindableDevicesUpdated"

    // Device Remote Status strings
    static let AddressUnavailable = "Address Unavailable"
    static let DeviceOffline = "Offline"

    // Confirmation Messages
    static let RemoveDeviceConfirmationMessage = "Are you sure you want to remove the device from your account?"

    // BLE advertising filter (must match embedded fmc_adv_magic.h)
    static let FMCAdvManufPrefix: [UInt8] = [0xFF, 0xFF, 0x46, 0x4D, 0x43]
}
