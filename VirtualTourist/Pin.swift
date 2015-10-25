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
    @NSManaged var locality: Locality?
    var annotation: MKPointAnnotation?
    var arePhotosLoading: Bool = false
    var errorStr: String? = nil
    dynamic var thumbnailsLoadedCount = 0
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        locality = nil
        annotation = nil
        arePhotosLoading = false
        // asynchronously fetch location
        GeoCoder.getLocationForPin(self)
    }
    
    var coordinate: CLLocationCoordinate2D {
        
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    func getPhotosForPin() {
        
        arePhotosLoading = true
        errorStr = nil
        FlickrAPI.getPhotosFromFlickrForCoordinate(coordinate) { photos, errorStr in
            
            if let photos = photos {
                print(">>> pin photo count - before: \(photos.count)")
                for photo in photos {
                    var dictionary = [String:AnyObject]()
                    // Sanitize dictionary
                    dictionary[Photo.Key.title] = photo[Photo.Key.title] ?? ""
                    dictionary[Photo.Key.url_m] = photo[Photo.Key.url_m] ?? ""
                    dictionary[Photo.Key.url_t] = photo[Photo.Key.url_t]
                    if dictionary[Photo.Key.url_t] != nil {
                        self.sharedContext.performBlockAndWait {
                            dictionary[Photo.Key.pin] = self
                            _ = Photo(dictionary: dictionary, context: self.sharedContext)
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                }
                print(">>> pin photo count - after: \(photos.count)")
            } else if let errorStr = errorStr {
                print(errorStr)
                self.errorStr = errorStr
            } else {
                self.errorStr = "Unexpected condition in \(__FUNCTION__)"
                print(errorStr)
            }
            self.arePhotosLoading = false
        }
    }
    
    func getPhotoCount(completion_handler: (Int, String?) -> Void) {

        var sleeptime = 0
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            while self.arePhotosLoading {
                print(">>> Sleeping... \(sleeptime)")
                sleep(1)
                sleeptime++
                if sleeptime > 60 {
                    if self.errorStr == nil {
                        self.errorStr = ""
                    } else {
                        self.errorStr! += "\n"
                    }
                    self.errorStr! += "Time out when loading pictures"
                    break
                }
            }
            var count = Int()
            self.sharedContext.performBlockAndWait {
                count = self.photos.count
            }
            completion_handler(count, self.errorStr)
        }
    }
    
    func incrementLoadedThumbnailsCount() {

        thumbnailsLoadedCount++
    }
        
    // MARK: coredata
    
    var sharedContext: NSManagedObjectContext {

        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}
