//
//  MapViewController.swift
//  A1_iOS_susmitha_c0808833
//
//  Created by Susmitha Jamedar on 15/05/21.
//

import UIKit
import MapKit
import CoreLocation

class MKMapViewController: UIViewController {
    
    //MARK:- Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK:- Properties
    let locationManager = CLLocationManager()
    var markers = [MKPointAnnotation]()
    var midMarkers =  [MKPointAnnotation]()
    var userLocation = CLLocation()
    
    //MARK:- Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        getLocationPremission()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressedOnmap))
        self.mapView.addGestureRecognizer(longPressRecognizer)

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        
    }
    
    //MARK:- User Defined Functions
    
    @objc func longPressedOnmap(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began{
            if markers.count == 3{
                markers.removeAll()
                midMarkers.removeAll()
                let overlays = mapView.overlays.filter({ !($0 is MKUserLocation) })
                let annotations = mapView.annotations.filter({ !($0 is MKUserLocation) })
                mapView.removeAnnotations(annotations)
                self.mapView.removeOverlays(overlays)
            }
            let touchPoint = gestureRecognizer.location(in: mapView)
            let location = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate =  location
            
            switch markers.count {
            case 0:
                annotation.title = "A"
            case 1:
                annotation.title = "B"
            case 2:
                annotation.title = "C"
            default:
                print("defualt")
            }
            let cllocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            annotation.subtitle = self.calculateDistanceInMiles(loc1: cllocation, loc2: userLocation)
           
            
           
            
            markers.append(annotation)

            
            if markers.count == 3{
                for i in 0..<self.markers.count{
                    let last = MKPointAnnotation()
                    if markers.indices.contains(i+1){
                        last.coordinate = markers[i].coordinate.midCoordinate(location: markers[i+1].coordinate)
                        last.title = self.calculateDistanceInMiles(loc1: markers[i].coordinate.cllocation(), loc2: markers[i+1].coordinate.cllocation())
                        midMarkers.append(last)
                    }else{
                        let final = MKPointAnnotation()
                        final.coordinate = markers[i].coordinate.midCoordinate(location: markers[0].coordinate)
                        final.title = self.calculateDistanceInMiles(loc1: markers[i].coordinate.cllocation(), loc2: markers[0].coordinate.cllocation())
                        midMarkers.append(final)
                        print(i)
                    }
                    
                }
            }

            
            self.addMarkers()
        }
        
    }
    
    //MARK: Request for location
    func getLocationPremission() {
        let status = self.locationAuthorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
            
        case .denied, .restricted:
            print("location access denied")
        case .notDetermined:
        print("notDetermined")
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    //MARK: Add Markers
    func addMarkers() {
        mapView?.delegate = self
        mapView?.addAnnotations(markers)
        mapView?.addAnnotations(midMarkers)
        var locations = markers.map { $0.coordinate}
        let polyline = MKPolyline(coordinates: &locations, count: locations.count)
        mapView?.addOverlay(polyline)
        
        let polygon = MKPolygon(coordinates: &locations, count: locations.count)
        mapView?.addOverlay(polygon)
        
    }
    
    
    
    //MARK:- Button Actions
    @IBAction func routeButtonTapped(_ button: UIButton) {
       
    }
    
    
    
}
//MARK:- MapView Delegate
extension MKMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    
   
        if annotation is MKUserLocation {
               return nil
           }

      
        if self.markers.contains(where: {$0.coordinate.latitude == annotation.coordinate.latitude}){
            let reuseIdentifier = "pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
    
    
                annotationView?.image = #imageLiteral(resourceName: "placeholder")
    
                return annotationView
        }else{
            let reuseId = "reuseid"
            var av = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if av == nil {
                av = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                lbl.backgroundColor = .clear
                lbl.textColor = .black
                //lbl.alpha = 0.5
                lbl.tag = 42
                lbl.numberOfLines = 0
                lbl.font = UIFont.systemFont(ofSize: 10)
                av?.addSubview(lbl)
                av?.canShowCallout = false
                av?.frame = lbl.frame
            }
            else {
                av?.annotation = annotation
            }

            let lbl = av?.viewWithTag(42) as! UILabel
            lbl.text = annotation.title!

            return av
        }
         
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKCircle{
            
        } else if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 3
            
            return renderer
            
        } else if overlay is MKPolygon{
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print(view)
    }
    
}
//MARK:- Location Manager Delegate
extension MKMapViewController : CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        // self.myLocation = locValue
        
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        if let firstLoc = locations.first{
            self.userLocation = firstLoc
            let viewRegion = MKCoordinateRegion(center: locValue, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(viewRegion, animated: false)
        }
    }
}


//MARK:- Extensions

extension CLLocationCoordinate2D {
    // MARK: CLLocationCoordinate2D+MidPoint
    func midCoordinate(location:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        
        let lon1 = longitude * .pi / 180
        let lon2 = location.longitude * .pi / 180
        let lat1 = latitude * .pi / 180
        let lat2 = location.latitude * .pi / 180
        let dLon = lon2 - lon1
        let x = cos(lat2) * cos(dLon)
        let y = cos(lat2) * sin(dLon)
        
        let lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) )
        let lon3 = lon1 + atan2(y, cos(lat1) + x)
        
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat3 * 180 / .pi, lon3 * 180 / .pi)
        return center
    }
}

extension CLLocationCoordinate2D{
    func cllocation() -> CLLocation{
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
}

extension UIViewController{
    func locationAuthorizationStatus() -> CLAuthorizationStatus {
        let locationManager = CLLocationManager()
        var locationAuthorizationStatus : CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            locationAuthorizationStatus =  locationManager.authorizationStatus
        } else {
            // Fallback on earlier versions
            locationAuthorizationStatus = CLLocationManager.authorizationStatus()
        }
        return locationAuthorizationStatus
    }
    
    func calculateDistanceInMiles(loc1:CLLocation,loc2:CLLocation) -> String{
        let distanceInMeters = loc1.distance(from: loc2)
        if(distanceInMeters <= 1609){
            let s =   String(format: "%.2f", distanceInMeters * 0.000621371192)
            return s + " Mile"
        }else{
            let s =   String(format: "%.2f", distanceInMeters * 0.000621371192)
            return s + " Miles"
            
        }
    }
    
}
