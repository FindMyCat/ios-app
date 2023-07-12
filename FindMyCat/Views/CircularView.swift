//
//  CircularView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/12/23.
//

import Foundation

import UIKit

class CircularViewLayout: UIStackView {
    private let circleRadius: CGFloat = 120

    private let startAngle: CGFloat = .pi / 4 // Starting angle in radians
    private let endAngle: CGFloat = 3 * .pi / 4 // Ending angle in radians

    func addCircularView(_ view: UIView) {
        addSubview(view)
        layoutCircularViews()
    }

    private func layoutCircularViews() {
        let viewCount = subviews.count

        let angleRange = endAngle - startAngle

        let angleStep = angleRange / CGFloat(viewCount == 1 ? viewCount : viewCount - 1)

        let centerX = bounds.width / 2
        let centerY = (4 * bounds.height) / 5

        for (index, view) in subviews.enumerated() {
            let angle = -1 * (startAngle + CGFloat(viewCount - index - 1) * angleStep)
            let xOffset = circleRadius * CGFloat(cos(angle)) + centerX - (view.bounds.width / 2)
            let randomYOffset = Float.random(in: 10...100)
            let yOffset = (circleRadius * CGFloat(sin(angle)) + centerY - (view.bounds.width / 2))
            view.transform = CGAffineTransform(translationX: xOffset, y: yOffset - CGFloat(randomYOffset))
        }
    }
}
