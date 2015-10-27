//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Jason on 1/31/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//  Modified by Laurent Nicolas on October 2015.
//

import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retrieving images
    
    func imageForURL(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        if path == nil {
            print("ERROR: \(__FUNCTION__): Empty path for identifier: \(identifier)")
            return nil
        }
        
        // First try the memory cache
        if let image = inMemoryCache.objectForKey(path!) as? UIImage {
            // print("found in cache \(path)")
            return image
        }
        
        // Next try the hard drive
        if let data = NSData(contentsOfFile: path!) {
            //print(">>> found on drive \(path)")
            return UIImage(data: data)
        }

        return nil
    }
    
    // MARK: - Saving images
    
    func storeImageForURL(image: UIImage?, withIdentifier identifier: String, reportError: Bool = true) {
        
        // If the identifier is empty, return
        if identifier == "" {
            print("\(__FUNCTION__): Empty identifier")
            return
        }
        
        let path = pathForIdentifier(identifier)
        if path == nil {
            print("\(__FUNCTION__): Empty path")
            return
        }
        
        // If the image is nil, remove images from the cache
        if image == nil {
            inMemoryCache.removeObjectForKey(path!)
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path!)
                //print(">>> deleted file for \(path)")
            } catch let error as NSError {
                if reportError {
                    print("Failed to remove file for: \(identifier), path: \(path), error: \(error.localizedDescription)")
                }
            }
            
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path!)
        
        // And in documents directory
        let data = UIImagePNGRepresentation(image!)!
        if !data.writeToFile(path!, atomically: true) {
            print("ERROR: Failed to save file for: \(identifier), path: \(path)")
        }
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String? {
        
        var path = NSURL(string: identifier)?.resourceSpecifier
        if path == nil {
            print(">>> Invalid identifier: \(identifier)")
            return nil
        }
        path = path!.stringByReplacingOccurrencesOfString("/", withString: "_")

        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(path!)
        
        return fullURL.path
    }
}