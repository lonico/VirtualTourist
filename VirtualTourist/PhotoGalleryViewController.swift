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
    @IBOutlet var deleteButton: UIBarButtonItem!
    
    var pinView: MKPinAnnotationView!
    var pin: Pin!
    var viewIsActive = false
    var defaultImage: UIImage? = nil
    var needToReloadData = false
    var reloading = false
    var dontEnableActions = false
    
    // if false, full image is displayed on selection
    var deleteOnSelection = true

    // MARK: view life cycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        noImageLabel.hidden = true
        activityWheel.startAnimating()
        
        if defaultImage == nil {
            defaultImage = UIImage(named: "VirtualTourist_120")
        }
        
        // Asynchronously wait for flickr photo fetches on internet, if any, and take action
        updateViewOncePhotosAreFetched(true)
        
        // Fetch photos for pin in coredata
        sharedContext.performBlockAndWait {
            do {
                try self.fetchedResultsController.performFetch()
            } catch let error as NSError {
                print("ERROR: fetch: \(error.localizedDescription)")
            }
            print(">>> Fetched results: \(self.fetchedResultsController.fetchedObjects?.count)")
        }
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self

        // Show small map and pin
        let region = MKCoordinateRegion(center: (pinView.annotation?.coordinate)!, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(pinView.annotation!)
    }

    override func viewWillAppear(animated: Bool) {
        
        navigationController?.navigationBarHidden = false
        self.newCollectionButton.enabled = false
        viewIsActive = true
        
        // Observe changes to pin.thumbnailsLoadedCount, it indicates an image is loaded
        pin.addObserver(self, forKeyPath: "thumbnailsLoadedCount", options: NSKeyValueObservingOptions.New, context: nil)
        
        // Don't enable the button only all photos and all thumbnails are loaded
        if !self.needToReloadData && !self.loadingInProgress() {
            self.newCollectionButton.enabled = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        viewIsActive = false
        pin.removeObserver(self, forKeyPath: "thumbnailsLoadedCount")
        super.viewWillDisappear(animated)
    }
    
    // MARK: collectionView data source delegates
    
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
        if deleteOnSelection {
            cell.photo?.deletePhoto(true)
        } else if newCollectionButton.enabled {
            // only switch to new controller if all images are loaded
            showFullImage(cell.photo)
        } else {
            AlertController.Alert(msg: "Can't display details while images are loading", title: "").dispatchAlert(self)
        }
    }
    
    // show new viewController with larger image
    func showFullImage(photo: Photo?) {
        
        if photo != nil {
            let vc = storyboard?.instantiateViewControllerWithIdentifier("PhotoFullViewController") as! PhotoFullViewController
            vc.photo = photo
            viewIsActive = false
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(vc, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: action buttons

    @IBAction func newCollectionActionTouchUp(sender: UIButton) {
        
        print(">>> TODO action button - delete old images and photo info")
        dispatch_async(dispatch_get_main_queue()) {
            self.newCollectionButton.enabled = false
            self.dontEnableActions = true
            self.activityWheel.startAnimating()
            self.noImageLabel.hidden = true
            self.deletePhotos()
            self.pin.getPhotosForPin()
            self.updateViewOncePhotosAreFetched(false)
        }
    }

    @IBAction func deleteButtonActionTouchUp(sender: AnyObject) {
        if deleteOnSelection {
            deleteOnSelection = false
            deleteButton.tintColor = UIColor.lightGrayColor()
        } else {
            deleteOnSelection = true
            deleteButton.tintColor = UIColor.redColor()
        }
    }
    
    // MARK: view updates
    
    func updateViewOncePhotosAreFetched(initView: Bool) {
        
        // wait for flickr photos to be fetched, and take action
        pin.getPhotoCount() { count, errorStr in
            if let errorStr = errorStr {
                let alert = AlertController.Alert(msg: errorStr, title: AlertController.AlertTitle.OpenURLError) { action in
                    self.activityWheel.stopAnimating()
                }
                alert.dispatchAlert(self)
            } else if count == 0 {
                dispatch_async(dispatch_get_main_queue()) {
                    self.noImageLabel.hidden = false
                    self.activityWheel.stopAnimating()
                    self.dontEnableActions = false
                    if !self.needToReloadData && !self.loadingInProgress() {
                        self.newCollectionButton.enabled = true
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityWheel.stopAnimating()
                    self.dontEnableActions = false
                    if (initView) {
                        // the images may already be loaded when viewDidLoad is called
                        self.reloadCollectionView()
                    }
                    // Otherwise, KVO events will be triggered
                }
            }
        }
    }
    
    func reloadCollectionView() {
        self.reloading = true
        self.needToReloadData = false
        self.collectionView.reloadData()
        self.reloading = false
        if !self.needToReloadData && !self.dontEnableActions && !self.loadingInProgress() {
            self.newCollectionButton.enabled = true
        }
    }
    
    // MARK: delegate to process changes to Photo store
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            //print(">>> INSERTING photo")
            //self.collectionView.reloadData()
            break
        case .Delete:
            print(">>> Deleting photo")
            dispatch_async(dispatch_get_main_queue()) {
                self.reloadCollectionView()
            }
        case .Move:
            break
        case .Update:
            if let photo = anObject as? Photo {
                print(">>> UPDATING photo: isLoaded=\(photo.thumbNail_status.isLoaded)")
            }
        }
    }

    // MARK: KVO observer, a change in thumbnails count indicates a reload is required
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "thumbnailsLoadedCount" {
            let value = change?[NSKeyValueChangeNewKey] as! Int
            print(">>> KVO: reloading, as image was added: \(value)")
            if !self.reloading {
                dispatch_async(dispatch_get_main_queue()) {
                    self.reloadCollectionView()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: coredata
        
    func deletePhotos() {
        
        dispatch_async(dispatch_get_main_queue()) {
            let photos = self.fetchedResultsController.fetchedObjects as! [Photo]
            for photo in photos {
                photo.deletePhoto(false)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func loadingInProgress() -> Bool {
        
        var isLoading = false
        if pin.arePhotosLoading {
            return true
        }
        sharedContext.performBlockAndWait {
            let photos = self.fetchedResultsController.fetchedObjects as! [Photo]
            for photo in photos {
                if photo.thumbNail_status.isLoading {
                    isLoading = true
                    break
                }
            }
        }
        return isLoading
    }

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
