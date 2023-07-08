//
//  PreciseFindableDevice.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/7/23.
//

import Foundation
import NearbyInteraction
import CoreBluetooth
import simd

// Base struct to save the last location values
struct UWBLocation {
    var distance: Float
    var direction: simd_float3
    var elevation: Int
    var noUpdate: Bool
}

class PreciseFindableDevice {
    var blePeripheral: CBPeripheral         // BLE Peripheral instance
    var rxCharacteristic: CBCharacteristic? // Characteristics to be used when receiving data
    var txCharacteristic: CBCharacteristic? // Characteristics to be used when sending data

    var bleUniqueID: Int
    var blePeripheralName: String            // Name to display
    var blePeripheralStatus: String?         // Status to display
    var bleTimestamp: Int64                  // Last time that the device adverstised
    var uwbLocation: UWBLocation?

    init(peripheral: CBPeripheral, uniqueID: Int, peripheralName: String, timeStamp: Int64 ) {

        self.blePeripheral = peripheral
        self.bleUniqueID = uniqueID
        self.blePeripheralName = peripheralName
        self.blePeripheralStatus = statusDiscovered
        self.bleTimestamp = timeStamp
        self.uwbLocation = UWBLocation(distance: 0,
                                    direction: SIMD3<Float>(x: 0, y: 0, z: 0), elevation: NINearbyObject.VerticalDirectionEstimate.unknown.rawValue,
                                    noUpdate: false)
    }
}
