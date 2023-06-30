//
//  MapboxView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import UIKit
import MapboxMaps
import CoreLocation
import MapKit

class MapboxView: UIView, CLLocationManagerDelegate {
    internal var mapView: MapView!
    var locationManager: CLLocationManager!
    
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
    
    private func setupMapView() {
        let myResourceOptions = ResourceOptions(accessToken: apiKey)
        
        let userLocation = locationManager.location?.coordinate
        let screenSize: CGRect = UIScreen.main.bounds
        let myCameraOptions = CameraOptions(center: userLocation, padding: UIEdgeInsets(top: 0,left: 0,bottom: (screenSize.height * 30 / 100) ,right: 0), zoom: 15)
        
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions, cameraOptions: myCameraOptions)
        mapView = MapView(frame: bounds, mapInitOptions: myMapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.location.options.puckType = .puck2D()
        
        addSubview(mapView)
    }
    
    public func updatePositions(positions: [Position]) {
        for position in positions {
            let latitude = position.latitude
            let longitude = position.longitude
            
            // Create a new `CLLocationCoordinate2D` with the updated latitude and longitude
            let newCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            self.addViewAnnotation(at: newCoordinate)
        }
        
        let coordinates = positions.map { position in
            return CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
        }
        
        if (coordinates.count > 1) {
            let polygon = Geometry.polygon(Polygon([coordinates]))
            let newCamera = mapView.mapboxMap.camera(for: polygon, padding: .init(top: 100, left: 100, bottom: 300, right: 100), bearing: 0, pitch: 0)
            mapView.camera.ease(to: newCamera, duration: 0.5)
        } else {
            let newCoordinate = CLLocationCoordinate2D(latitude: positions[0].latitude, longitude: positions[0].longitude)
            mapView.camera.ease(to: CameraOptions(center: newCoordinate, zoom: 14), duration: 0.7)
        }
    }
    
    // Handle location authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            setupMapView()
        }
    }
    
    func centerToUserLocation() {
        let userLocation = locationManager.location?.coordinate
        
        mapView.camera.ease(to: CameraOptions(center: userLocation! as CLLocationCoordinate2D, zoom: 15), duration: 1.3)
        
    }

    @objc private func devicesUpdated(_ notification: Notification) {

        // Update UI using the updated devices array
    }
    
    @objc private func positionsUpdated(_ notification: Notification) {

        print("positionUpdated: ", SharedData.getPositions())
        mapView.viewAnnotations.removeAll()
        print(mapView.viewAnnotations.annotations)
        // Update UI using the updated positions array
        updatePositions(positions: SharedData.getPositions())
    }
    
    private func addViewAnnotation(at coordinate: CLLocationCoordinate2D) {
        let options = ViewAnnotationOptions(
            geometry: Point(coordinate),
            width: 60,
            height: 60,
            allowOverlap: false,
            anchor: ViewAnnotationAnchor.bottom
        )
        let sampleView = CustomAnnotationView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        sampleView.setIcon(systemName: "pawprint", color: .black)
        
                
        try? mapView.viewAnnotations.add(sampleView, options: options)
    }
    
    override func didMoveToWindow() {
        NotificationCenter.default.addObserver(self, selector: #selector(devicesUpdated(_:)), name: Notification.Name(Constants.DevicesUpdatedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(positionsUpdated(_:)), name: Notification.Name(Constants.PositionsUpdatedNotificationName), object: nil)
    }
}

