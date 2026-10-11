//
//  DeviceStatus.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 8/24/26.
//

import Foundation

/// The collar's latest telemetry from the device-status service, one entry
/// per event kind. A new kind is a new struct and field here.
struct DeviceState: Decodable {
    let command: CommandResult?
    let network: NetworkState?
    let radio: RadioState?

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// Field names are the collar's own JSON keys, so nothing is mapped; a "_s"
// suffix is a duration in seconds, "_ms" a Unix time in milliseconds.

/// Result of the last ping or mode change.
struct CommandResult: Decodable {
    let id: Int
    let receivedAt: Date
    let command: String
    let status: String
    let reason: String?
    let method: String?
    let satellites: Double?
    let elapsed_s: Double?
    let uptime_s: Double?
}

/// The eDRX cycle granted on the last attach: the longest a command waits.
struct NetworkState: Decodable {
    let id: Int
    let receivedAt: Date
    let edrx_s: Double?
    /// lte_lc_lte_mode: 7 is LTE-M.
    let mode: Int?
}

/// Which radio reaches the home station: "BLE", "LoRa" or "LTE".
struct RadioState: Decodable {
    let id: Int
    let receivedAt: Date
    let active: String
}
