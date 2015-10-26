//
//  Locality.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/18/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import Foundation
import CoreData

@objc(Locality)

class Locality: NSManagedObject {
    
    struct Key {
        static let name = "name"
        static let administrativeArea = "administrativeArea"
        static let country = "country"
        static let pin = "pin"
    }
    
    @NSManaged var name: String
    @NSManaged var administrativeArea: String
    @NSManaged var country: String
    @NSManaged var pin:Pin

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Locality", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.name = dictionary[Key.name] as! String
        self.administrativeArea = dictionary[Key.administrativeArea] as! String
        self.country = dictionary[Key.country] as! String
        self.pin = dictionary[Key.pin] as! Pin
    }

    var fullname: String {
        
        return [name, administrativeArea, country].joinWithSeparator(", ")
    }
}
