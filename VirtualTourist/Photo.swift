//
//  Photo.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/14/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    struct Key {
        static let title = "title"
        static let url_q = "url_q"
        static let url_m = "url_m"
    }
    
    @NSManaged var title: String
    @NSManaged var url_q: String
    @NSManaged var url_m: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: String], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = dictionary[Key.title]!
        self.url_q = dictionary[Key.url_q]!
        self.url_m = dictionary[Key.url_m]!
    }
}
