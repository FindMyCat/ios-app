//
//  ScanningView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 7/11/23.
//

import UIKit

class ScanningAnimationView: UIView {
    private let circleCount = 9
    private let strokeWidth: CGFloat = 0.5
    private let centerOfConcentricCirclesForAnimation = UIView()

    let strokeColor = UIColor.gray

    private var animationTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        let centerX = bounds.width / 2
        let centerY = (4 * bounds.height) / 5

        let radiusStep = 70.0

        for i in 0..<circleCount {
            let circleRadius = radiusStep * CGFloat(Double(i) * 0.6)
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), radius: circleRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            context.addPath(circlePath.cgPath)
            context.setStrokeColor(strokeColor.cgColor)
            context.setLineWidth(strokeWidth)
            context.strokePath()
        }

    }

    func startAnimation() {
        let centerX = bounds.width / 2
        let centerY = (4 * bounds.height) / 5
        let spread = 100
        let animationCircleFillColor = UIColor.systemGray

        /*! Creates a circular path around the view*/
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: spread, height: spread))

        /*! Position where the shape layer should be */
        let shapePosition = CGPoint(x: centerX, y: centerY)
        let rippleShape = CAShapeLayer()
        rippleShape.bounds = CGRect(x: 0, y: 0, width: spread, height: spread)
        rippleShape.path = path.cgPath
        rippleShape.fillColor = animationCircleFillColor.cgColor

        rippleShape.position = shapePosition
        rippleShape.opacity = 0

        /*! Add the ripple layer as the sublayer of the reference view */
        self.layer.addSublayer(rippleShape)

        /*! Create scale animation of the ripples */
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        scaleAnim.toValue = NSValue(caTransform3D: CATransform3DMakeScale(4, 4, 1))

        /*! Create animation for opacity of the ripples */
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0.2
        opacityAnim.toValue = nil

        /*! Group the opacity and scale animations */
        let animation = CAAnimationGroup()
        animation.animations = [scaleAnim, opacityAnim]
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.duration = CFTimeInterval(1)

        animation.repeatCount = .infinity
        rippleShape.add(animation, forKey: "rippleEffect")
    }
}

extension ScanningAnimationView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            setNeedsDisplay()
        }
    }
}
