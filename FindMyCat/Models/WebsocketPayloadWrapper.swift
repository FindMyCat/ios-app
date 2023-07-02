//
//  WebsocketPayloadWrapper.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation

enum PayloadType: String, Decodable {
    case device
    case position
}

struct PayloadWrapper: Decodable {
    let devices: [Device]?
    let positions: [Position]?

    private enum CodingKeys: String, CodingKey {
        case devices
        case positions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        devices = try container.decodeIfPresent([Device].self, forKey: .devices)
        positions = try container.decodeIfPresent([Position].self, forKey: .positions)
    }
}
