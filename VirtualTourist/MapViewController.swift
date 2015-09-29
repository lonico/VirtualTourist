//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/26/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let region = getSavedRegion() {
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = true
    }

    // detect a long press and add a new pin
    @IBAction func longPressGesture(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            let point = sender.locationInView(mapView)
            // CLLocationCoordinate2D(latitude: 40.738854666284, longitude: -105.455546187602)
            let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = coord2text(coordinate)
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a pin view with a "right callout accessory view".
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // This delegate method is implemented to respond to taps.     
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) -> Void {
        print("Tapped")
        let galleryVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoGallery")
        navigationController?.navigationBarHidden = false
        navigationController?.pushViewController(galleryVC!, animated: true)
        print(self.navigationController)
    }
    
    // Delegate to respond to dragging a pin
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            // title is read only.  We need to create a new annotation and 
            // replace the existing one
            print("drag \(view.annotation?.coordinate)")
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = (view.annotation?.coordinate)!
            newAnnotation.title = coord2text((view.annotation?.coordinate)!)
            mapView.removeAnnotation(view.annotation!)
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    // Delegate to respond to moving or zooming the map region
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveRegion(mapView.region)
    }
    
    // TODO: Refactor in a different file
    // Service function, coordinate to String
    func coord2text(coordinate: CLLocationCoordinate2D) -> String {
        
        let _long = doubleToTextWithNWSE(coordinate.longitude, direction: .longitude)
        let _lat = doubleToTextWithNWSE(coordinate.latitude, direction: .latitude)
        return _long + " - " + _lat
    }
    
    func doubleToTextWithNWSE(var value: Double, direction: Direction) -> String {
        
        var suffix = ""
        if value < 0 {
            switch direction {
            case .longitude: suffix = LongitudeSuffix.negative
            case .latitude: suffix = LatitudeSuffix.negative
            }
            value = -value
        } else if value > 0 {
            switch direction {
            case .longitude: suffix = LongitudeSuffix.positive
            case .latitude: suffix = LatitudeSuffix.positive
            }
        }
        return String(format: "%.3f%@", value, suffix)
    }
    
    
    enum Direction {
        case longitude
        case latitude
    }
    
    struct RegionKeys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let deltaLat = "deltaLat"
        static let deltaLong = "deltaLong"
    }
    
    struct LongitudeSuffix {
        static let positive = "E"
        static let negative = "W"
    }
    
    struct LatitudeSuffix {
        static let positive = "N"
        static let negative = "S"
    }
    
    func saveRegion(region: MKCoordinateRegion) {
        
        var dictionary = [String: AnyObject]()
        dictionary[RegionKeys.latitude] = region.center.latitude
        dictionary[RegionKeys.longitude] = region.center.longitude
        dictionary[RegionKeys.deltaLat] = region.span.latitudeDelta
        dictionary[RegionKeys.deltaLong] = region.span.longitudeDelta
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(dictionary, forKey: "mapViewRegion")
    }
    
    func getSavedRegion() -> MKCoordinateRegion! {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let dictionary = defaults.dictionaryForKey("mapViewRegion") {
            let center = CLLocationCoordinate2D(latitude: dictionary[RegionKeys.latitude] as! CLLocationDegrees, longitude: dictionary[RegionKeys.longitude] as! CLLocationDegrees)
            let span = MKCoordinateSpan(latitudeDelta: dictionary[RegionKeys.deltaLat]  as! CLLocationDegrees, longitudeDelta: dictionary[RegionKeys.deltaLong] as! CLLocationDegrees)
            return MKCoordinateRegion(center: center, span: span)
        }
        return nil
    }
}
