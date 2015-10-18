//
//  Pin.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/14/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    var arePhotosLoading: Bool = false
    var errorStr: String! = nil
    dynamic var imagesLoaded = 0
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        arePhotosLoading = false
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    func getPhotosForPin(completion_handler: (String?) -> Void) {
        
        arePhotosLoading = true
        FlickrAPI.getPhotosFromFlickrForCoordinate(coordinate) { photos, errorStr in
            if let photos = photos {
                for photo in photos {
                    var dictionary = photo
                    dictionary[Photo.Key.pin] = self
                    _ = Photo(dictionary: dictionary, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                print("pin photo count: \(photos.count)")
            } else if let errorStr = errorStr {
                print(errorStr)
                self.errorStr = errorStr
            } else {
                self.errorStr = "Unexpected condition in \(__FUNCTION__)"
                print(errorStr)
            }
            self.arePhotosLoading = false
            completion_handler(errorStr)
        }
    }
    
    func getPhotoCount(completion_handler: (Int?, String?) -> Void) {
        var sleeptime = 0
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            while self.arePhotosLoading {
                print("Sleeping...")
                sleep(1)
                sleeptime++
                if sleeptime > 60 {
                    self.errorStr + "\nTime out when loading pictures"
                    break
                }
            }
            completion_handler(self.photos.count, self.errorStr)
        }
    }
    
    func incrementLoadedImageCount() {
        imagesLoaded++
        didChangeValueForKey("imagesLoaded")
    }
    
    // MARK: coredata
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

}
