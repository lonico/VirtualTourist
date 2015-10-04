//
//  PhotoGalleryViewController.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/28/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import UIKit
import MapKit

class PhotoGalleryViewController: UIViewController, UICollectionViewDataSource {
    
    let span = MKCoordinateSpanMake(0.1, 0.2)
    var pinView: MKAnnotationView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityWheel: UIActivityIndicatorView!
    
    var imageURLs: [(String?, String, String)]?
    var imageDataStore = [String:UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        
        self.activityWheel.startAnimating()
        testme((self.pinView.annotation?.coordinate)!) { urls, error in
            if let urls = urls {
                print(urls[0])
                self.imageURLs = urls
                dispatch_async(dispatch_get_main_queue()) {
                    self.activityWheel.stopAnimating()
                    print("loading data")
                    let time0 = NSDate()
                    self.collectionView.reloadData()
                    print("elapsed reloadData: \(-time0.timeIntervalSinceNow)")
                }
            }
        }
        
        let region = MKCoordinateRegion(center: (pinView.annotation?.coordinate)!, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(pinView.annotation!)
        
    }

    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = false
        //print(self.collectionView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize))
        //print(self.collectionView.systemLayoutSizeFittingSize(UILayoutFittingExpandedSize))
        //print(self.collectionView.intrinsicContentSize())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let vc = segue.destinationViewController as! PhotoFullViewController
        let cell = sender as! CollectionViewCell
        let url_m = cell.url_m
        let image = imageDataStore[url_m]
        if image == nil {
            getImageForURLPath(url_m) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    vc.photoImage = image
                    vc.refresh_image()
                }
            }
        } else {
            vc.photoImage = image
        }
    }

    // MARK: CollectionView data source delegates
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath)
        let url = imageURLs?[indexPath.row]
        if url != nil {
            let url_t = url!.1
            let image = imageDataStore[url_t]
            if image == nil {
                getImageForURLPath(url_t) { image in
                    if image != nil {
                        (cell as! CollectionViewCell).image.image = image
                        (cell as! CollectionViewCell).url_m = url!.2
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            let section = indexPath.section
                            if (collectionView.numberOfSections() > 0 && collectionView.numberOfItemsInSection(section) > 0 && collectionView.indexPathsForVisibleItems().contains(indexPath)) {
                                // TODO: reloadData generates too many requests
                                //collectionView.reloadData()
                                // reloadItemsAtIndexPaths crashed if the view goes out of focus
                                collectionView.reloadItemsAtIndexPaths([indexPath])
                            }
                        }
                    }
                }
            } else {
                (cell as! CollectionViewCell).image.image = image
                (cell as! CollectionViewCell).url_m = url!.2
            }
        }
        return cell
    }
    
    func getImageForURLPath(urlString: String, completion_handler: (UIImage?) -> Void) {
        
        let time0 = NSDate()
        getImageFromURLString(urlString) { webImage in
            if let image = webImage {
                self.imageDataStore[urlString] = image
            }
            print("elapsedN: \(-time0.timeIntervalSinceNow)")
            completion_handler(webImage)
        }
    }
}
