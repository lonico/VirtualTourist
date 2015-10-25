//
//  PhotoFullViewController.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/1/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import UIKit

class PhotoFullViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var photo: Photo!
    var photoImage = UIImage?()
    var errorStr: String? = nil
    
    override func viewWillAppear(animated: Bool) {
        
        let image = photo!.fullImage
        if image == nil {
            photo!.getFullImageFromUrl() { image, errorStr in
                if image != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.photoImage = image
                        self.refresh_image()
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.errorStr = errorStr
                        self.show_alert()
                    }
                }
            }
        } else {
            self.photoImage = image
            self.refresh_image()
        }
        super.viewWillAppear(true)
    }
    
    // MARK: tap action
    @IBAction func tapGesture(sender: UITapGestureRecognizer) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UI Uupdates
    
    func refresh_image() {
        
        activityIndicator.stopAnimating()
        imageView.image = photoImage
    }
    
    func show_alert() {
        
        let alert = AlertController.Alert(msg: errorStr, title: AlertController.AlertTitle.OpenURLError) { action in
            dispatch_async(dispatch_get_main_queue()) {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        alert.dispatchAlert(self)
    }
}