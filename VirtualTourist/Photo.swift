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
    }
    
    var thumbNail: UIImage! {
        
        get {
            return PhotoDB.Cache.imageCache.imageForURL(url_t)
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
}
