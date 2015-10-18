//
//  PhotoGalleryViewController.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/28/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    let span = MKCoordinateSpanMake(0.1, 0.2)
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityWheel: UIActivityIndicatorView!
    @IBOutlet var noImageLabel: UILabel!
    @IBOutlet var newCollectionButton: UIButton!
    
    var pinView: MKPinAnnotationView!
    var pin: Pin!
    var viewIsActive = false
    var defaultImage: UIImage? = nil
    var needToReloadData = false
    var reloading = false
    var reload_count = 0
    let max_reload_count = 60
    
    // MARK: view life cycle
    override func viewDidLoad() {
        
        print("ViewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.noImageLabel.hidden = true
        self.activityWheel.startAnimating()
        
        if defaultImage == nil {
            defaultImage = UIImage(named: "VirtualTourist_120")
        }
        
        pin.getPhotoCount() { count, errorStr in
            if let count = count {
                if count == 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.noImageLabel.hidden = false
                        self.activityWheel.stopAnimating()
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        print("activityWheel.stopAnimating")
                        self.activityWheel.stopAnimating()
                        self.collectionView.reloadData()
                        self.newCollectionButton.enabled = true
                    }
                }
            } else {
                let alert = AlertController.Alert(msg: errorStr, title: AlertController.AlertTitle.OpenURLError) { action in
                    self.activityWheel.stopAnimating()
                }
                alert.dispatchAlert(self)
            }
        }
        
        // Step 2: Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("fetch error: \(error.localizedDescription)")
        }
        
        print("Fetched results: \(fetchedResultsController.fetchedObjects?.count)")
        
        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self

        let region = MKCoordinateRegion(center: (pinView.annotation?.coordinate)!, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(pinView.annotation!)
        
        reload_asynch()
    }

    override func viewWillAppear(animated: Bool) {
        
        navigationController?.navigationBarHidden = false
        newCollectionButton.enabled = false
        viewIsActive = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        viewIsActive = false
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: CollectionView data source delegates
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath)
        let photo = fetchedResultsController.fetchedObjects![indexPath.row] as? Photo
        if photo != nil {
            let image = photo?.thumbNail
            if image == nil {
                (cell as! CollectionViewCell).image.image = defaultImage
                (cell as! CollectionViewCell).photo = nil
                needToReloadData = true
            } else {
                (cell as! CollectionViewCell).image.image = image
                (cell as! CollectionViewCell).photo = photo
            }
        }
        return cell
    }
    
    // MARK: collectionView delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print(">>> selected Cell")
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CollectionViewCell
        if cell.photo != nil {
            let vc = storyboard?.instantiateViewControllerWithIdentifier("PhotoFullViewController") as! PhotoFullViewController
            let image = cell.photo.fullImage
            if image == nil {
                cell.photo.getFullImageFromUrl() { image, errorStr in
                    if image != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            vc.photoImage = image
                            vc.refresh_image()
                        }
                    } else {
                        let alert = AlertController.Alert(msg: errorStr, title: AlertController.AlertTitle.OpenURLError) { action in
                            vc.dismissViewControllerAnimated(true, completion: nil)
                        }
                        alert.dispatchAlert(vc)
                    }
                }
            } else {
                vc.photoImage = image
            }
            viewIsActive = false
            presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    // TODO: revisit with codedata
    func getImageForURLPath(urlString: String, completion_handler: (UIImage?, String?) -> Void) {
        
//        HttpRequest.sharedInstance().getImageFromURLString(urlString) { webImage, errorStr in
//            completion_handler(webImage, errorStr)
//        }
    }
    
    @IBAction func newCollectionActionTouchUp(sender: UIButton) {
        print("TODO action button")
    }
    
    // MARK: delegate to process changes to Photo store
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            print("INSERTING")
            //self.collectionView.reloadData()
        case .Delete: break
        case .Move: break
        case .Update:
            print("UPDATING")
        }
    }
    
    func reload_asynch() {
        if pin.imagesLoaded == pin.photos.count || reload_count >= max_reload_count {
            // stop scheduling more reloads
            print("reloading stopped!")
            return
        }
        reload_count++
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            sleep(1)
            print("reloading, as needed")
            if self.needToReloadData && !self.reloading {
                self.needToReloadData = false
                self.reloading = true
                dispatch_async(dispatch_get_main_queue()) {
                    self.collectionView.reloadData()
                    self.reloading = false
                    self.reload_asynch()
                }
            } else {
                self.reload_asynch()
            }
        }
    }
    
    // MARK: coredata
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let request = NSFetchRequest(entityName: "Photo")
        
        request.sortDescriptors = [NSSortDescriptor(key: Photo.Key.url_t, ascending: true)]
        request.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStackManager.sharedInstance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
        }()
    
}
