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
        if let region = MKCoordinateRegion.getSavedRegion() {
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = true
        super.viewWillAppear(true)
    }

    // detect a long press and add a new pin
    @IBAction func longPressGesture(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            let point = sender.locationInView(mapView)
            // CLLocationCoordinate2D(latitude: 40.738854666284, longitude: -105.455546187602)
            let coordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = coordinate.coord2text()
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
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            //pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // This delegate method is implemented to respond to tapping a callout button.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) -> Void {
        print("Tapped")
        mapView.deselectAnnotation(annotationView.annotation, animated: true)
        let galleryVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoGallery") as! PhotoGalleryViewController
        galleryVC.pinView = annotationView
        navigationController?.pushViewController(galleryVC, animated: true)
    }
    
    // This delegate method is implemented to respond to tapping a pin.
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Selected")
        mapView.deselectAnnotation(view.annotation, animated: true)
        let galleryVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoGallery") as! PhotoGalleryViewController
        galleryVC.pinView = view
        navigationController?.pushViewController(galleryVC, animated: true)
    }
    
    // Delegate to respond to dragging a pin
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            // title is read only.  We need to create a new annotation and 
            // replace the existing one
            print("drag \(view.annotation?.coordinate)")
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = (view.annotation?.coordinate)!
            newAnnotation.title = view.annotation?.coordinate.coord2text()
            mapView.removeAnnotation(view.annotation!)
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    // Delegate to respond to moving or zooming the map region
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapView.region.saveRegion()
    }
    
}
