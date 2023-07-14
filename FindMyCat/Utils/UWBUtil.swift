//
//  UWBUtils.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/6/23.
//

import Foundation
import NearbyInteraction
import simd
import os.log

class UWBUtils {

    let logger = Logger(subsystem: "Utils", category: String(describing: UWBUtils.self))
    // MARK: - Utils.
    // Provides the azimuth from an argument 3D directional.
    func azimuth(_ direction: simd_float3) -> Float {
        if NISession.deviceCapabilities.supportsDirectionMeasurement {
            return asin(direction.x)
        } else {
            return atan2(direction.x, direction.z)
        }
    }

    // Provides the elevation from the argument 3D directional.
    func elevation(_ direction: simd_float3) -> Float {
        return atan2(direction.z, direction.y) + .pi / 2
    }

    // TODO: Refactor
    func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }

    func getDirectionFromHorizontalAngle(rad: Float) -> simd_float3 {
        logger.log("Horizontal Angle in deg = \(self.rad2deg(Double(rad)))")
        return simd_float3(x: sin(rad), y: 0, z: cos(rad))
    }

    func getElevationFromInt(elevation: Int?) -> String {
        guard elevation != nil else {
            return "UNKNOWN"
        }
        // TODO: Use Localizable String
        switch elevation {
        case NINearbyObject.VerticalDirectionEstimate.above.rawValue:
            return "ABOVE"
        case NINearbyObject.VerticalDirectionEstimate.below.rawValue:
            return "BELOW"
        case NINearbyObject.VerticalDirectionEstimate.same.rawValue:
            return "SAME"
        case NINearbyObject.VerticalDirectionEstimate.aboveOrBelow.rawValue, NINearbyObject.VerticalDirectionEstimate.unknown.rawValue:
            return "UNKNOWN"
        default:
            return "UNKNOWN"
        }
    }

}
