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
    var photoImage = UIImage?()
    var errorStr: String? = nil
    
    override func viewWillAppear(animated: Bool) {
        
        if photoImage != nil {
            refresh_image()
        } else if errorStr != nil {
            show_alert()
        }
        super.viewWillAppear(true)
    }
    
    // MARK: tap action
    @IBAction func tapGesture(sender: UITapGestureRecognizer) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
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