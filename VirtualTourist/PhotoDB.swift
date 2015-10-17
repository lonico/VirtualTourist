//
//  PhotoDB.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/14/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

// Manage photos for a pin
// 1) retrieve and persist URLs from flickr
// 2) cache images in memory and local storage

import MapKit
import CoreData

struct PhotoDB {
    
    static var areUrlsLoaded = false
    static var numberOfUrls: Int? = nil
    static var errorStr: String? = nil
    
    static func getImageURLsForCoordinate(pin: Pin, completion_handler: (String?) -> Void) {
        
        FlickrAPI.getImagesFromFlickrForCoordinate(pin.coordinate) { urls, errorStr in
            if let urls = urls {
                numberOfUrls = urls.count
                for url in urls {
                    var dictionary = [String: AnyObject]()
                    var (title, url_t, url_m) = url
                    if title == nil {
                        title = ""
                    }
                    dictionary[Photo.Key.title] = title
                    dictionary[Photo.Key.url_t] = url_t
                    dictionary[Photo.Key.url_m] = url_m
                    dictionary[Photo.Key.pin] = pin
                    _ = Photo(dictionary: dictionary, context: sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            } else if let errorStr = errorStr {
                print(errorStr)
                PhotoDB.errorStr = errorStr
            } else {
                print("Unexpected condition in \(__FUNCTION__)")
            }
            areUrlsLoaded = true
            print("photoDB: \(numberOfUrls)")
            completion_handler(errorStr)
        }
    }
    
    static func getUrlCount(completion_handler: (Int?, String?) -> Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)){
            while !areUrlsLoaded {
                sleep(1)
            }
            completion_handler(numberOfUrls, errorStr)
        }
    }
    
    // MARK: coredata
    
    static var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // MARK: image cache
    
    struct Cache {
        static let imageCache = ImageCache()
    }

}
