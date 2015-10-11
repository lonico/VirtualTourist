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
    
    override func viewWillAppear(animated: Bool) {
        
        if photoImage != nil {
            refresh_image()
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
}