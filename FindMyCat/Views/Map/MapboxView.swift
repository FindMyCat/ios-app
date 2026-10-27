//
//  MapboxView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import UIKit
import MapboxMaps
import MapKit

class MapboxView: UIView, CLLocationManagerDelegate {
    internal var mapView: MapView!
    private var locationManager: CLLocationManager!
    private var isMapfirstLoad = true

    // fetch mapbox api key from info.plist
    private var apiKey: String {
      get {

        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
          fatalError("Couldn't find file 'Info.plist'.")
        }

        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "MBXAccessToken") as? String else {
          fatalError("Couldn't find key 'MBXAccessToken' in 'Info.plist'.")
        }
        return value
      }
    }

    // MARK: - View Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Request location authorization
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMapView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        addObserverForNotifications()
    }

    // MARK: - Setup

    private func setupMapView() {
        let userLocation = locationManager.location?.coordinate
        let screenSize: CGRect = UIScreen.main.bounds
        let myCameraOptions = CameraOptions(center: userLocation, padding: UIEdgeInsets(top: 0, left: 0, bottom: (screenSize.height * 30 / 100), right: 0), zoom: 15)

        let myMapInitOptions = MapInitOptions(cameraOptions: myCameraOptions)
        mapView = MapView(frame: bounds, mapInitOptions: myMapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        mapView.location.options.puckType = .puck2D()

        addSubview(mapView)
    }

    private func addObserverForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(devicesUpdated(_:)), name: Notification.Name(Constants.DevicesUpdatedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionsUpdated(_:)), name: Notification.Name(Constants.PositionsUpdatedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceSelected(_:)), name: Notification.Name(Constants.DeviceSelectedNotificationName), object: nil)
    }

    // MARK: - Location Manager Delegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            setupMapView()
        }
    }

    // MARK: - Actions

    @objc private func devicesUpdated(_ notification: Notification) {

        // Update UI using the updated devices array
    }

    @objc private func positionsUpdated(_ notification: Notification) {
        // Update UI using the updated positions array
        guard mapView != nil else { return }
        updatePositions(positions: SharedData.getPositions())
    }

    @objc private func deviceSelected(_ notification: Notification) {
        guard let deviceId = notification.userInfo?["deviceId"] as? Int else {
            if let camera = calculateCameraForPositions(positions: SharedData.getPositions()) {
                mapView.camera.ease(to: camera, duration: 0.6)
            }
            return
        }

        guard let position = SharedData.getPositions().first(where: { $0.deviceId == deviceId }) else { return }

        let coordinate = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
        mapView.camera.ease(to: CameraOptions(center: coordinate, padding: UIEdgeInsets(top: 0, left: 0, bottom: bounds.height * 0.35, right: 0), zoom: 16), duration: 0.6)
    }

    // MARK: - Public Functions

    public func updatePositions(positions: [Position]) {
        // If more than one positions, we calculate camera for the polygon
        if let newCamera = calculateCameraForPositions(positions: positions) {

            if isMapfirstLoad {
                mapView.camera.ease(to: newCamera, duration: 0.3) { [weak self] _ in
                    self?.mapView.viewAnnotations.removeAll()
                    self?.addAnnotations(positions: positions)
                }
                isMapfirstLoad = false
            } else {
                mapView.viewAnnotations.removeAll()
                addAnnotations(positions: positions)
            }

        } else if let position = positions.first {
            // One position, camera is on the coordinate as center
            let newCoordinate = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)

            mapView.viewAnnotations.removeAll()
            addAnnotations(positions: positions)
            if isMapfirstLoad {
                mapView.camera.ease(to: CameraOptions(center: newCoordinate, zoom: 14), duration: 0.5) { [weak self] _ in
                    self?.mapView.viewAnnotations.removeAll()
                    self?.addAnnotations(positions: positions)
                }
                isMapfirstLoad = false
            } else {
                mapView.viewAnnotations.removeAll()
                addAnnotations(positions: positions)
            }

        } else {
            mapView.viewAnnotations.removeAll()
        }
    }

    public func centerToUserLocation() {
        let userLocation = locationManager.location?.coordinate

        mapView.camera.ease(to: CameraOptions(center: userLocation! as CLLocationCoordinate2D, zoom: 15), duration: 1.3)
    }

    // MARK: - Private Functions
    private func calculateCameraForPositions(positions: [Position]) -> CameraOptions? {
        guard positions.count > 1 else {
            return nil
        }

        var coordinates = positions.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        let polygon = Geometry.polygon(Polygon([coordinates]))
        return mapView.mapboxMap.camera(for: polygon, padding: .init(top: 150, left: 100, bottom: 400, right: 100), bearing: 0, pitch: 0)
    }

    /// A translucent circle of each position's accuracy radius, under the pins.
    private func showAccuracy(positions: [Position]) {
        guard mapView.mapboxMap.isStyleLoaded else { return }

        let circles = FeatureCollection(features: positions.compactMap { position -> Feature? in
            guard let accuracy = position.accuracy, accuracy > 0 else { return nil }
            let center = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
            return Feature(geometry: .polygon(Polygon(center: center, radius: accuracy, vertices: 64)))
        })

        let sourceId = "accuracy"
        if mapView.mapboxMap.sourceExists(withId: sourceId) {
            mapView.mapboxMap.updateGeoJSONSource(withId: sourceId, geoJSON: .featureCollection(circles))
            return
        }

        var source = GeoJSONSource(id: sourceId)
        source.data = .featureCollection(circles)
        var layer = FillLayer(id: sourceId, source: sourceId)
        layer.fillColor = .constant(StyleColor(.systemBlue))
        layer.fillOpacity = .constant(0.15)
        layer.fillOutlineColor = .constant(StyleColor(.systemBlue))
        try? mapView.mapboxMap.addSource(source)
        try? mapView.mapboxMap.addLayer(layer)
    }

    private func addAnnotations(positions: [Position]) {
        showAccuracy(positions: positions)

        for position in positions {
            let newCoordinate = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
            let options = ViewAnnotationOptions(
                geometry: Point(newCoordinate),
                width: 60,
                height: 60,
                allowOverlap: false,
                anchor: ViewAnnotationAnchor.bottom
            )

            if let device = SharedData.getDevices().first(where: { $0.id == position.deviceId }) {
                let frame = CGRect(x: 0, y: 0, width: 60, height: 60)
                let pin = CustomAnnotationView(frame: frame)
                pin.setEmoji(emoji: (device.attributes?.emoji)!)

                try? mapView.viewAnnotations.add(pin, options: options)
            }
        }
    }

}
