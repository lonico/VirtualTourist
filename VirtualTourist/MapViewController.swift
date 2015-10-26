//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/26/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    // cross-ref to find pin associated with MapView annotation
    var pins = [MKPointAnnotation: Pin]()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let region = MKCoordinateRegion.getSavedRegion() {
            mapView.setRegion(region, animated: true)
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetch error, \(error.localizedDescription)")
        }
        
        // TODO: only if we want to managed pin insertion/deletion
        fetchedResultsController.delegate = self

        if let stored_pins = fetchedResultsController.fetchedObjects as? [Pin] {
            //print(">>> adding pins")
            for pin in stored_pins {
                //print(">>> adding pin")
                let annotation = MKPointAnnotation()
                annotation.updateCoordinateAndTitle(pin.latitude, longitude: pin.longitude)
                if (pin.locality != nil) {
                    annotation.setLocalityAndCoordTitles(pin.locality!)
                }
                mapView.addAnnotation(annotation)
                pins[annotation] = pin
                pin.annotation = annotation
            }
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
            // print(">>> ending drop and drag action")
            _ = Pin(coordinate: currentAnnotation.coordinate, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
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
        galleryVC.pinView = view as! MKPinAnnotationView
        galleryVC.pin = pins[view.annotation as! MKPointAnnotation]
        navigationController?.pushViewController(galleryVC, animated: true)
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
    
    // MARK: delegate to process changes to Pin store
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            //print(">>> INSERTING pin")
            let pin = anObject as! Pin
            pins[currentAnnotation] = pin
            pin.annotation = currentAnnotation
            // let's proactively search pictures in flickr
            // error reporting will be done when the results are needed in collectionView
            pin.getPhotosForPin()
        case .Delete:
            //print(">>> DELETING pin")
            break
        case .Move:
            //print(">>> MOVING pin")
            break
        case .Update:
            //print(">>> UPDATING pin")
            break
        }
    }
    
    // MARK: coredata
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let request = NSFetchRequest(entityName: "Pin")
        
        request.sortDescriptors = [NSSortDescriptor(key: "longitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStackManager.sharedInstance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
        }()

}
