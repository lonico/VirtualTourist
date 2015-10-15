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

    // MARK: use long gesture to create and drag a pin
    
    var currentAnnotation = MKPointAnnotation()
    
    // detect a long press and create a draggable pin
    @IBAction func longPressGesture(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            // create a "pin" once a long tap is recognized
            let point = sender.locationInView(mapView)
            let annotation = MKPointAnnotation()
            updateLocation(annotation, point: point)
            mapView.addAnnotation(annotation)
            currentAnnotation = annotation
        }
        
        if sender.state == UIGestureRecognizerState.Changed {
            // enable the pin to be dragged around
            let point = sender.locationInView(mapView)
            updateLocation(currentAnnotation, point: point)
        }
        
        if sender.state == UIGestureRecognizerState.Ended {
            // finalize the pin location
            let point = sender.locationInView(mapView)
            updateLocation(currentAnnotation, point: point)
            currentAnnotation.updateTitle()
            print("ending drop and drag action")
        }
    }
    
    // MARK: - MKMapViewDelegate functions
    
    // Delegate to create a pin view (the pin itself)
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        pinView!.setDragState(.Dragging, animated: true)
        return pinView
    }
    
    // Delegate to respond to tapping a pin.
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        let galleryVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoGallery") as! PhotoGalleryViewController
        galleryVC.pinView = view
        navigationController?.pushViewController(galleryVC, animated: true)
    }
    
    // Delegate to respond to dragging a pin
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == .Ending {
            print("ending drag action")
            view.setDragState(.Ending, animated: true)
            print("drag \(view.annotation?.coordinate)")
            if let annotation = view.annotation as? MKPointAnnotation {
                annotation.updateTitle()
            }
        }
    }
    
    // Delegate to respond to moving or zooming the map region
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        mapView.region.saveRegion()
    }
    
    // MARK: utility
    
    func updateLocation(annotation: MKPointAnnotation, point: CGPoint) {
        
        // CLLocationCoordinate2D(latitude: 40.738854666284, longitude: -105.455546187602)
        let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        annotation.coordinate = coordinate
    }
}
