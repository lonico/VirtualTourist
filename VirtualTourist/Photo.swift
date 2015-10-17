//
//  Photo.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/14/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)

class Photo: NSManagedObject {
    
    struct Key {
        static let title = "title"
        static let url_m = "url_m"
        static let url_t = "url_t"
        static let pin = "pin"
    }
    
    @NSManaged var title: String
    @NSManaged var url_m: String
    @NSManaged var url_t: String
    @NSManaged var pin: Pin
    var isLoadingTB = false
    var isLoadingFI = false
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = dictionary[Key.title] as! String
        self.url_m = dictionary[Key.url_m] as! String
        self.url_t = dictionary[Key.url_t] as! String
        self.pin = dictionary[Key.pin] as! Pin
        // let's preload thumbnails, as we need them in the collection view
        loadThumbnailFromUrl()
        // TODO: find a way to reload data on VC.
    }
    
    var thumbNail: UIImage! {
        
        get {
            let image = PhotoDB.Cache.imageCache.imageForURL(url_t)
            if image == nil {
                // just in case the previous load timed out
                loadThumbnailFromUrl()
            }
            return image
        }
        
        set {
            PhotoDB.Cache.imageCache.storeImageForURL(newValue, withIdentifier:url_t)
        }
    }
    
    var fullImage: UIImage! {
        
        get {
            return PhotoDB.Cache.imageCache.imageForURL(url_m)
        }
        
        set {
            PhotoDB.Cache.imageCache.storeImageForURL(newValue, withIdentifier:url_m)
        }
    }
    
    func loadThumbnailFromUrl() {
        
        if self.isLoadingTB {
            return
        }
        
        self.isLoadingTB = true
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            HttpRequest.sharedInstance().getImageFromURLString(self.url_t) { image, strerror in
                
                if image != nil {
                    self.thumbNail = image!
                } else if strerror != nil {
                    // TODO: report errors, but not for every thumbnail
                    print(strerror)
                } else {
                    print("Unexpected error in \(__FUNCTION__): getImageFromURLString")
                }
                self.isLoadingTB = false
            }
        }
    }

    func getFullImageFromUrl(completion_handler: (image: UIImage!, sterror: String!) -> Void) {
        
        if self.isLoadingFI {
            return
        }
        
        self.isLoadingFI = true
        
        HttpRequest.sharedInstance().getImageFromURLString(self.url_m) { image, strerror in
                
            if image != nil {
                self.fullImage = image!
            } else if strerror != nil {
                print(strerror)
            } else {
                print("Unexpected error in \(__FUNCTION__): getImageFromURLString")
            }
            self.isLoadingFI = false
            completion_handler(image: image, sterror: strerror)
        }
    }
}

