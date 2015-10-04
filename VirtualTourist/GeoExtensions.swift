//
//  GeoExtensions.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/29/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import MapKit

// MARK: utility to convert coordinate to user friendly text string
extension CLLocationCoordinate2D {
    
    // Service function, coordinate to String
    func coord2text() -> String {
        
        let _long = doubleToTextWithNWSE(self.longitude, direction: .longitude)
        let _lat = doubleToTextWithNWSE(self.latitude, direction: .latitude)
        return _long + " - " + _lat
    }
    
    func doubleToTextWithNWSE(var value: Double, direction: Direction) -> String {
        
        var suffix = ""
        if value < 0 {
            switch direction {
            case .longitude: suffix = LongitudeSuffix.negative
            case .latitude: suffix = LatitudeSuffix.negative
            }
            value = -value
        } else if value > 0 {
            switch direction {
            case .longitude: suffix = LongitudeSuffix.positive
            case .latitude: suffix = LatitudeSuffix.positive
            }
        }
        return String(format: "%.3f%@", value, suffix)
    }
    
    enum Direction {
        case longitude
        case latitude
    }
    
    struct LongitudeSuffix {
        static let positive = "E"
        static let negative = "W"
    }
    
    struct LatitudeSuffix {
        static let positive = "N"
        static let negative = "S"
    }
}

//MARK: save and restore region to/from user defaults
extension MKCoordinateRegion {
    
    struct RegionKeys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let deltaLat = "deltaLat"
        static let deltaLong = "deltaLong"
    }
    
    func saveRegion() {
        
        var dictionary = [String: AnyObject]()
        dictionary[RegionKeys.latitude] = self.center.latitude
        dictionary[RegionKeys.longitude] = self.center.longitude
        dictionary[RegionKeys.deltaLat] = self.span.latitudeDelta
        dictionary[RegionKeys.deltaLong] = self.span.longitudeDelta
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(dictionary, forKey: "mapViewRegion")
    }
    
    static func getSavedRegion() -> MKCoordinateRegion! {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let dictionary = defaults.dictionaryForKey("mapViewRegion") {
            let center = CLLocationCoordinate2D(
                        latitude:  dictionary[RegionKeys.latitude]  as! CLLocationDegrees,
                        longitude: dictionary[RegionKeys.longitude] as! CLLocationDegrees)
            let span = MKCoordinateSpan(
                        latitudeDelta:  dictionary[RegionKeys.deltaLat]  as! CLLocationDegrees,
                        longitudeDelta: dictionary[RegionKeys.deltaLong] as! CLLocationDegrees)
            return MKCoordinateRegion(center: center, span: span)
        }
        return nil
    }
}