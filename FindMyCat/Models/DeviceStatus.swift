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
    let firmware: FirmwareState?
    let sim: SimState?

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
    /// Set by the server when it placed the WiFi scan ("ok").
    let access_points: Int?
    /// Set by the server when it placed the cell scan ("ok").
    let cell_towers: Int?
    let accuracy_m: Double?
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

/// Version of the running firmware, reported once per boot when LTE comes up.
/// After an update, a new version here means the new image is running.
struct FirmwareState: Decodable {
    let id: Int
    let receivedAt: Date
    let version: String
}

/// Hologram's view of the SIM, stored by the server each time /sim is fetched.
/// An active session means LTE is attached and a command can reach the collar.
struct SimState: Decodable {
    let id: Int
    let receivedAt: Date
    /// Hologram link state as a label, e.g. "LIVE" reads "Active".
    let state: String?
    let lastConnectTime: Date?
    let sessionActive: Bool?

    private struct Session: Decodable { let active: Bool }
    private enum CodingKeys: String, CodingKey { case id, receivedAt, state, lastConnectTime, lastSession }

    // Flattens lastSession so the status screen lists it as a plain row.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        receivedAt = try c.decode(Date.self, forKey: .receivedAt)
        state = try c.decodeIfPresent(String.self, forKey: .state).map(Self.label)
        lastConnectTime = try c.decodeIfPresent(String.self, forKey: .lastConnectTime).flatMap(Self.hologramTime.date)
        sessionActive = try c.decodeIfPresent(Session.self, forKey: .lastSession)?.active
    }

    /// Hologram NetworkState values, as the app names them.
    private static func label(_ state: String) -> String {
        if state.hasSuffix("-PENDING") { return "Changing…" }
        switch state {
        case "LIVE": return "Active"
        case "PAUSED-USER": return "Paused"
        case "PAUSED-SYS": return "Paused by Hologram"
        case "INACTIVE", "INACTIVE-TESTED", "FACTORY": return "Not activated"
        case "TEST-ACTIVATE", "TEST-AUTOACTIVATE", "TEST-HIBERNATE": return "Test mode"
        case "FROZEN": return "Frozen"
        case "DEAD": return "Deactivated"
        default: return state
        }
    }

    /// Hologram timestamps are UTC "yyyy-MM-dd HH:mm:ss".
    private static let hologramTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
