//
//  TimeUtil.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/10/23.
//

import Foundation
import os.log

class DateTimeUtil {

    static let logger = Logger(subsystem: "Utils", category: String(describing: DateTimeUtil.self))

    public static func relativeTime(dateString: String) -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Set the locale if needed
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Set the time zone if needed

        if let date = dateFormatter.date(from: dateString) {

            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.maximumUnitCount = 1
            formatter.allowsFractionalUnits = false

            let now = Date()
            let components = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: date, to: now)

            if let year = components.year, year >= 1 {
                return formatter.string(from: date, to: now)! + " ago"
            } else if let month = components.month, month >= 1 {
                return formatter.string(from: date, to: now)! + " ago"
            } else if let week = components.weekOfYear, week >= 1 {
                return formatter.string(from: date, to: now)! + " ago"
            } else if let day = components.day, day >= 1 {
                return formatter.string(from: date, to: now)! + " ago"
            } else if let hour = components.hour, hour >= 1 {
                return formatter.string(from: date, to: now)! + " ago"
            } else if let minute = components.minute, minute >= 1 {
                return formatter.string(from: date, to: now)! + " ago"
            } else {
                return "Just now"
            }

        } else {
            logger.error("Invalid date string")
        }
        return ""
    }
}
