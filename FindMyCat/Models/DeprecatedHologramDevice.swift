//
//  DeprecatedHologramDevice.swift
//  Unused: the app sends commands through the device-commands service now
//  FindMyCat
//
//  Created by Sahas Chitlange on 8/3/23.
//

import Foundation

class DeprecatedHologramDevicesResponse: Decodable {
    var success: Bool
    var data: [DeprecatedHologramDevice]?
    var error: String?

    init(success: Bool, data: [DeprecatedHologramDevice]?, error: String?) {
        self.success = success
        self.data = data
        self.error = error
    }
}

class DeprecatedHologramDevice: Decodable {

    var id: Int
    var name: String

    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}
