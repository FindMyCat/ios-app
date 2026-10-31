//
//  CollarModelView.swift
//  FindMyCat
//

import SceneKit
import UIKit

final class CollarModelView: UIView {
    private let sceneView = SCNView()
    private let track = CAShapeLayer()
    private let ring = CAShapeLayer()
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
}
