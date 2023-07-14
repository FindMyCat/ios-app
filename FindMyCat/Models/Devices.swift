//
//  Devices.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import Foundation

class Device: Decodable {

    struct Attributes: Decodable {
        var emoji: String?
    }

    var id: Int
    var name: String
    var uniqueId: String
    var attributes: Attributes?
    var groupId: Int?
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

    init(name: String, id: Int, uniqueId: String) {
        self.name = name
        self.id = id
        self.uniqueId = uniqueId
    }

    func getName() -> String {
        return self.name
    }
}
