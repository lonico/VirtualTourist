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
    
    struct Status {
        var isLoading: Bool = false
        var isLoaded: Bool = false
        var strerror: String? = nil
    }
    
    @NSManaged var title: String
    @NSManaged var url_m: String
    @NSManaged var url_t: String
    @NSManaged var pin: Pin?
    
    var thumbNail_status = Status()
    var fullImage_status = Status()
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = dictionary[Key.title] as! String
        self.url_m = dictionary[Key.url_m] as! String
        self.url_t = dictionary[Key.url_t] as! String
        self.pin = dictionary[Key.pin] as? Pin
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
            } else if !thumbNail_status.isLoaded {
                thumbNail_status.isLoaded = true
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
            // don't report error on delete (fullImage == nil), as fullImage may not have been stored
            PhotoDB.Cache.imageCache.storeImageForURL(newValue, withIdentifier:url_m, reportError: fullImage != nil)
        }
    }
    
    func loadThumbnailFromUrl() {
        
        if thumbNail_status.isLoading {
            return
        }
        self.thumbNail_status.isLoading = true
        HttpRequest.sharedInstance().getImageFromURLString(self.url_t) { image, strerror in
            
            if image != nil {
                self.sharedContext.performBlockAndWait {
                    self.thumbNail = image!
                    self.thumbNail_status.isLoading = false
                    self.pin?.incrementLoadedThumbnailsCount()
                }
                self.thumbNail_status.isLoaded = true
            } else if strerror != nil {
                // TODO: report errors, but not for every thumbnail
                print(strerror)
                self.thumbNail_status.strerror = strerror
            } else {
                print("Unexpected error in \(__FUNCTION__): getImageFromURLString")
                self.thumbNail_status.strerror = "unexpected error"
            }
            self.thumbNail_status.isLoading = false
        }
    }

    func getFullImageFromUrl(completion_handler: (image: UIImage!, sterror: String!) -> Void) {
        
        if fullImage_status.isLoading {
            completion_handler(image: nil, sterror: "loading")
            return
        }
        
        if self.url_m == "" {
            let errorStr = "Empty URL for image"
            print(errorStr)
            completion_handler(image: nil, sterror: errorStr)
            return
        }
        
        fullImage_status.isLoading = true
        HttpRequest.sharedInstance().getImageFromURLString(self.url_m) { image, strerror in
            
            self.sharedContext.performBlockAndWait {
                if image != nil {
                    self.fullImage = image!
                    self.fullImage_status.isLoaded = true
                } else if strerror != nil {
                    print("\(__FUNCTION__): I was here")
                    print(strerror)
                } else {
                    print("Unexpected error in \(__FUNCTION__): getImageFromURLString")
                }
                self.fullImage_status.isLoading = false
            }
            completion_handler(image: image, sterror: strerror)
        }
    }
    
    // MARK: coredata
    
    var sharedContext: NSManagedObjectContext {
        
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func deletePhoto(save: Bool) {
        
        self.sharedContext.performBlockAndWait {
            // delete the photo object
            self.sharedContext.deleteObject(self)
            if save {
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    override func prepareForDeletion() {
        //print(">>> prepare for deletion")
        self.thumbNail = nil
        self.fullImage = nil
        super.prepareForDeletion()
    }

}

