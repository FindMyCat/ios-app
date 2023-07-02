//
//  Devices.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import Foundation

class Device: Decodable {
    var id: Int?
    var attributes: [String: String]?
    var groupId: Int?
    var name: String
    var uniqueId: String?
    var status: String?
    var lastUpdate: String?
    var positionId: Int?
    var geofenceIds: [Int]?
    var phone: String?
    var model: String?
    var contact: String?
    var category: String?
    var disabled: Bool?
    var expirationTime: Date?

    init(name: String) {
        self.name = name
    }

    func getName() -> String {
        return self.name
    }
}
