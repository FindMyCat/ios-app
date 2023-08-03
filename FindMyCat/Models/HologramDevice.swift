//
//  HologramDevice.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 8/3/23.
//

import Foundation

class HologramDevicesResponse: Decodable {
    var success: Bool
    var data: [HologramDevice]?
    var error: String?

    init(success: Bool, data: [HologramDevice]?, error: String?) {
        self.success = success
        self.data = data
        self.error = error
    }
}

class HologramDevice: Decodable {

    var id: Int
    var name: String

    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}
