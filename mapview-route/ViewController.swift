//
//  ViewController.swift
//  mapview-route
//
//  Created by Роман Мельник on 9/23/19.
//  Copyright © 2019 Роман Мельник. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}


class ViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var firstPointTextField: UITextField!
    @IBOutlet weak var firstPointButton: UIButton!
    @IBOutlet weak var secondPointTextField: UITextField!
    @IBOutlet weak var secondPointButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var roadButton: UIButton!
    
    // MARK: - Properties
    
    var firstCoordinate = CLLocationCoordinate2D(latitude: 50.470135, longitude: 30.631999)
//    var secondCoordinate = CLLocationCoordinate2D(latitude: 0.7, longitude: 0.701225)
    let firstAnnotation = MKPointAnnotation()
    var secondAnnotation = MKPointAnnotation()
    var firstText = "Новая почта"
    var roadButtonText = "Проложить маршрут"

    
    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        prepareView()
    }
    
    //MARK: - UI
    func prepareView() {
        roadButton.setTitle(roadButtonText, for: .normal)
        roadButton.backgroundColor = UIColor.green
        firstPointTextField.text = firstText
        firstAnnotation.title = firstText
    }

    //MARK: - Helper
    func mapView(_ mapView: MKMapView,rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 4.5
        renderer.strokeColor = UIColor.green
        return renderer
    }
    

    func removePoint() {
        mapView.removeAnnotations(mapView.annotations)
    }

    func removeRoad() {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    func geoDecoderName(point: CLLocationCoordinate2D){
        let NewPoint = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(NewPoint) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
            
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
            var street: String = ""
            var streetNum: String = ""
            var temp: String = ""
            var city: String = ""
            var adminArea: String = ""
            var country: String = ""
            
            if placemark.thoroughfare != nil { street = "\(placemark.thoroughfare!) " }
            if placemark.subThoroughfare != nil { streetNum = "\(placemark.subThoroughfare!), "}
            if (placemark.thoroughfare != nil) || (placemark.subThoroughfare != nil) {temp = ","}
            if placemark.locality != nil { city = "\(placemark.locality!), "}
            if placemark.administrativeArea != nil {adminArea = "\(placemark.administrativeArea!), "}
            if placemark.country != nil {country = "\(placemark.country!)"}
            let address = ("\(street)\(streetNum)\(temp)\(city)\(adminArea)\(country)")
            


            DispatchQueue.main.async {
                self.firstPointTextField.text = self.firstText
                self.firstAnnotation.title = self.firstText
                self.secondPointTextField.text = "\(address)"
                self.secondAnnotation.title = "\(address)"
            }
            self.addAnnotation(coordinate: point)
        }
    }
    
    func addAnnotation(coordinate:CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = secondAnnotation.title
        mapView.addAnnotation(secondAnnotation)
        mapView.addAnnotation(firstAnnotation)
    }
    
    
    
    func  route(firstCoordinate: CLLocationCoordinate2D, secondCoordinate: CLLocationCoordinate2D) {
//        removeRoad()
        firstAnnotation.coordinate = firstCoordinate
        secondAnnotation.coordinate = secondCoordinate
        
        mapView.showAnnotations([firstAnnotation,secondAnnotation], animated: true)
        
        let firstItem = MKMapItem(placemark: MKPlacemark(coordinate: firstCoordinate))
        let secondItem = MKMapItem(placemark: MKPlacemark(coordinate: secondCoordinate))
        
        let request = MKDirections.Request()
        request.source = firstItem
        request.destination = secondItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                NSLog("Error of requesting: \(error.debugDescription)")
                return
            }
            if response.routes.count > 0 {
                let route = response.routes.first!
                self.mapView.addOverlay(route.polyline, level: .aboveLabels)
//                let rect = route.polyline.boundingMapRect
//                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
    }
    
    
     // MARK: - Actions
    @IBAction func roadButtonTouchUpInside(_ sender: Any) {
        route(firstCoordinate: firstCoordinate, secondCoordinate: secondAnnotation.coordinate)
        firstPointTextField.text = firstText
    }
    
    @IBAction func tapGuesture(_ sender: UITapGestureRecognizer) {
        removePoint()
        removeRoad()
        if sender.state == .ended{
            let locationInView = sender.location(in: mapView)
            let tappedCoordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
            geoDecoderName(point: tappedCoordinate)
            secondAnnotation.coordinate = tappedCoordinate
        }
    }
}
