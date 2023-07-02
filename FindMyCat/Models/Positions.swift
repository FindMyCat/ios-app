//
//  Positions.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/25/23.
//

import Foundation

class Position: Decodable {

    struct Attributes: Decodable {
            var sat: Double
            var batteryLevel: Double
            var distance: Double
            var totalDistance: Double
            var motion: Bool
        }

    var id: Int
    var attributes: Attributes
    var deviceId: Int
    var serverTime: String
    var deviceTime: String
    var fixTime: String
    var outdated: Bool
    var valid: Bool
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var speed: Double
    var course: Double
    var address: String?
    var accuracy: Double
    var network: String?
}
