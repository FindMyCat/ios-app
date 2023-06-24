//
//  Devices.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import Foundation

class Device: Decodable {
    var name: String
    
    init(name: String) {
        self.name = name
    }

    public func getName() -> String {
        return self.name
    }
}
