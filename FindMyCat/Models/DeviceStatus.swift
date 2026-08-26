//
//  DeviceStatus.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 8/24/26.
//

import Foundation

struct DeviceStatus {
    let id: Int
    let deviceId: Int
    let command: String
    let status: String
    let reason: String?
    let method: String?
    let elapsedSeconds: Double?
    let uptimeSeconds: Double?
    let satellitesTracked: Double?
    let receivedAt: Date
}

struct DeviceStatusEnvelope: Decodable {
    struct Attributes: Decodable {
        let command: String?
        let status: String?
        let reason: String?
        let method: String?
        let elapsed: Double?
        let uptime: Double?
        let sat: Double?
    }

    struct PositionAttributesOnly: Decodable {
        let id: Int
        let deviceId: Int
        let attributes: Attributes?
    }

    let positions: [PositionAttributesOnly]?

    func extractStatuses(receivedAt: Date = Date()) -> [DeviceStatus] {
        (positions ?? []).compactMap { position in
            guard let attributes = position.attributes,
                  let command = attributes.command,
                  let status = attributes.status else {
                return nil
            }
            return DeviceStatus(
                id: position.id,
                deviceId: position.deviceId,
                command: command,
                status: status,
                reason: attributes.reason,
                method: attributes.method,
                elapsedSeconds: attributes.elapsed,
                uptimeSeconds: attributes.uptime,
                satellitesTracked: attributes.sat,
                receivedAt: receivedAt
            )
        }
    }
}
