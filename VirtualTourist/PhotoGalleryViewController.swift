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
                    self.collectionView.reloadData()
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
        let image = getImageForURLPath(cell.url_m)
        vc.photoImage = image
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
            let image = getImageForURLPath(url_t)
            if image != nil {
                (cell as! CollectionViewCell).image.image = image
                (cell as! CollectionViewCell).url_m = url!.2
            }
        }
            //cell.title.text = photoTitle
            //print(photoTitle)
        return cell
    }
    
    func getImageForURLPath(urlPath: String) -> UIImage? {
    
        var image = imageDataStore[urlPath]
        if image == nil {
            self.activityWheel.startAnimating()
            if let nsurl = NSURL(string: urlPath) {
                if let imageData = NSData(contentsOfURL: nsurl) {
                    image = UIImage(data: imageData)
                    if image != nil {
                        self.imageDataStore[urlPath] = image!
                    }
                } else {
                    print("Image does not exist at \(urlPath)")
                }
            } else {
                print("Invalid URL string: \(urlPath)")
            }
            self.activityWheel.stopAnimating()
        }
        return image
    }
}
