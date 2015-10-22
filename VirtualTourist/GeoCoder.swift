//
//  GeoCoder.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/18/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import MapKit
import CoreData

struct GeoCoder {
    
    static func getLocationForPin(pin: Pin) {
        
        let location = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            
            var errorStr: String! = nil
            var dictionary = [String: AnyObject]()
            dictionary[Locality.Key.name] = "not found"
            dictionary[Locality.Key.administrativeArea] = "-"
            dictionary[Locality.Key.country] = "-"
            dictionary[Locality.Key.pin] = pin
            print(location)
            if error != nil {
                errorStr = "Reverse geocoding error" + error!.localizedDescription
                print(errorStr)
            } else if placemarks?.count > 0 {
                let placemark = placemarks![0]
                print(placemark.locality)
                print(placemark.administrativeArea)
                print(placemark.country)
                //print(placemark)
                dictionary[Locality.Key.name] = placemark.locality ?? ""
                dictionary[Locality.Key.administrativeArea] = placemark.administrativeArea ?? ""
                dictionary[Locality.Key.country] = placemark.country ?? ""
                dictionary[Locality.Key.pin] = pin
            } else {
                errorStr = "Reverse geocoding error: no data received"
                print(errorStr)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                let locality = Locality(dictionary: dictionary, context: sharedContext)
                pin.annotation!.setLocalityAndCoordTitles(locality)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    // MARK: coredata
    
    static var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}