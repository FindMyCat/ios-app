//
//  MapboxView.swift
//  FindMyCat
//
//  Created by Sahas Chitlange on 6/24/23.
//

import UIKit
import MapboxMaps
import CoreLocation

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
    
    public func updatePosition(position: Position) {
        let latitude = position.latitude
        let longitude = position.longitude

        
        // Create a new `CLLocationCoordinate2D` with the updated latitude and longitude
        let newCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)


        mapView.camera.ease(to: CameraOptions(center: newCoordinate, zoom: 15), duration: 1.3)
    }
    
    // Handle location authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            setupMapView()
//            centerToUserLocation()
        }
    }
    
    func centerToUserLocation() {
        let userLocation = locationManager.location?.coordinate
        print("userLocation", userLocation!)
        
        mapView.camera.ease(to: CameraOptions(center: userLocation! as CLLocationCoordinate2D, zoom: 15), duration: 1.3)
        
    }
}

