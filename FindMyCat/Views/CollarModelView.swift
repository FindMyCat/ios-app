//
//  CollarModelView.swift
//  FindMyCat
//

import SceneKit
import UIKit

/// The collar's 3D model (collar-main.usdz) turning inside a progress ring,
/// with its LED drivable from code.
final class CollarModelView: UIView {
    enum LED {
        case off
        case steady(UIColor)
        case pulse(UIColor)
        /// Two blinks, like the collar's boot blink.
        case blinkTwice(UIColor)
    }

    private let sceneView = SCNView()
    private let track = CAShapeLayer()
    private let ring = CAShapeLayer()
    private var ledMaterials: [SCNMaterial] = []
    private static let ringWidth: CGFloat = 6

    private(set) var progress: Float = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        for layer in [track, ring] {
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = Self.ringWidth
            layer.lineCap = .round
            self.layer.addSublayer(layer)
        }
        track.strokeColor = UIColor.systemFill.cgColor
        ring.strokeColor = UIColor.systemBlue.cgColor
        ring.strokeEnd = 0

        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.isUserInteractionEnabled = false
        addSubview(sceneView)
        loadModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = Self.ringWidth * 3
        sceneView.frame = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: min(bounds.width, bounds.height) / 2 - Self.ringWidth,
                                startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true).cgPath
        track.path = path
        ring.path = path
    }

    private func loadModel() {
        guard let url = Bundle.main.url(forResource: "collar-main", withExtension: "usdz"),
              let scene = try? SCNScene(url: url) else { return }

        // Fusion exports Z-up: stand it up and centre it on the origin.
        let model = SCNNode()
        scene.rootNode.childNodes.forEach { model.addChildNode($0) }
        let (minBound, maxBound) = model.boundingBox
        model.pivot = SCNMatrix4MakeTranslation((minBound.x + maxBound.x) / 2,
                                                (minBound.y + maxBound.y) / 2,
                                                (minBound.z + maxBound.z) / 2)
        model.eulerAngles.x = -.pi / 2

        let turntable = SCNNode()
        turntable.addChildNode(model)
        turntable.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 14)))
        scene.rootNode.addChildNode(turntable)

        let radius = model.boundingSphere.radius
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.zNear = Double(radius) * 0.05
        camera.camera?.zFar = Double(radius) * 20
        camera.position = SCNVector3(0, radius * 0.7, radius * 2.6)
        camera.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(camera)

        // The LED keeps its Fusion material name (LEDSMD5630…).
        var materials: [SCNMaterial] = []
        scene.rootNode.enumerateChildNodes { node, _ in
            materials += node.geometry?.materials.filter { $0.name?.contains("LED") == true } ?? []
        }
        ledMaterials = materials

        sceneView.scene = scene
        sceneView.pointOfView = camera
    }

    func setProgress(_ value: Float, animated: Bool) {
        progress = value
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        ring.strokeEnd = CGFloat(value)
        CATransaction.commit()
    }

    func setLED(_ state: LED) {
        for material in ledMaterials {
            material.removeAllAnimations()
            material.emission.intensity = 1

            switch state {
            case .off:
                material.emission.contents = UIColor.black
            case .steady(let color):
                material.emission.contents = color
            case .pulse(let color):
                material.emission.contents = color
                let pulse = CABasicAnimation(keyPath: "emission.intensity")
                pulse.fromValue = 0.1
                pulse.toValue = 1
                pulse.duration = 0.9
                pulse.autoreverses = true
                pulse.repeatCount = .infinity
                material.addAnimation(pulse, forKey: "led")
            case .blinkTwice(let color):
                material.emission.contents = color
                let blink = CAKeyframeAnimation(keyPath: "emission.intensity")
                blink.values = [1, 0, 1, 0, 1]
                blink.keyTimes = [0, 0.25, 0.5, 0.75, 1]
                blink.calculationMode = .discrete
                blink.duration = 1.2
                material.addAnimation(blink, forKey: "led")
            }
        }
    }
}
