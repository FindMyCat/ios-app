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

/// Result of the last ping or mode change.
struct CommandResult: Decodable {
    let id: Int
    let receivedAt: Date
    let command: String
    let status: String
    let reason: String?
    let method: String?
    let satellites: Double?
    let elapsedSeconds: Double?
    let battery: Double?
    let uptimeSeconds: Double?

    private enum CodingKeys: String, CodingKey {
        case id, receivedAt, command, status, reason, method, satellites, battery
        case elapsedSeconds = "elapsed_s"
        case uptimeSeconds = "uptime_s"
    }
}

/// The eDRX cycle granted on the last attach: the longest a command waits.
struct NetworkState: Decodable {
    let id: Int
    let receivedAt: Date
    let edrxSeconds: Double?
    /// LTE mode the grant is for (lte_lc_lte_mode: 7 is LTE-M).
    let mode: Int?
    /// Unix ms the modem first woke in this eDRX phase; windows repeat every edrxSeconds.
    let wakeMs: Int64?

    private enum CodingKeys: String, CodingKey {
        case id, receivedAt, mode
        case edrxSeconds = "edrx_s"
        case wakeMs = "wake_ms"
    }
}

/// Which radio reaches the home station: "BLE", "LoRa" or "LTE".
struct RadioState: Decodable {
    let id: Int
    let receivedAt: Date
    let active: String
}
