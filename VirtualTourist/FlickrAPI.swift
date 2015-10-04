//
//  FlickrAPIs.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 9/29/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import GameKit
import MapKit

// TODO: move somewhere else

struct FlickrAPI {
    
    struct ArgKeys {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "47ab5778cf6752cd2eb7339c04b48d6d"
        static let EXTRAS = "url_t,url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
    }
    
    static func getImagesFromFlickrForCoordinate(coordinate: CLLocationCoordinate2D, completion_handler: ([(String?, String, String)]?, String?) -> Void) {
        
        let methodArguments = [
            "method": ArgKeys.METHOD_NAME,
            "api_key": ArgKeys.API_KEY,
            "bbox": FlickrAPI.createBoundingBoxString(coordinate),
            "safe_search": ArgKeys.SAFE_SEARCH,
            "extras": ArgKeys.EXTRAS,
            "format": ArgKeys.DATA_FORMAT,
            "nojsoncallback": ArgKeys.NO_JSON_CALLBACK
        ]
        
        FlickrAPI.getImagesFromFlickrBySearch(methodArguments) { photos, error in
            if let error = error {
                print("Error in getImagesFromFlickrBySearch: \(error)")
                completion_handler(nil, error)
            } else {
                print(photos?.count)
                var imageURLs = [(String?, String, String)]()
                var i = 0
                for photo in photos! {
                    let photoDictionary = photo //as [String: AnyObject]
                    
                    let photoTitle = photoDictionary["title"] as? String
                    if let imageUrlTString = photoDictionary["url_t"] as? String {
                        if let imageUrlMString = photoDictionary["url_m"] as? String {
                            imageURLs.append((photoTitle, imageUrlTString, imageUrlMString))
                            if i < 3 {
                                print(photoTitle)
                                i++
                            }
                        }
                    }
                }
                completion_handler(imageURLs, nil)
            }
        }
    }
    
    static func createBoundingBoxString(coordinate: CLLocationCoordinate2D) -> String {
        
        let BOUNDING_BOX_HALF_WIDTH = 0.1   // 1 degree = 111 km
        let BOUNDING_BOX_HALF_HEIGHT = 0.1
        let LAT_MIN = -90.0
        let LAT_MAX = 90.0
        let LON_MIN = -180.0
        let LON_MAX = 180.0
        
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH,  LON_MIN)
        let bottom_left_lat = max(latitude  - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon   = min(longitude + BOUNDING_BOX_HALF_WIDTH,  LON_MAX)
        let top_right_lat   = min(latitude  + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    /* Function makes first request to get a random page, then it makes a request to get all images from the random page */
    /* Images are shuffled in randam order */
    static func getImagesFromFlickrBySearch(methodArguments: [String : AnyObject], completion_handler: ([[String: AnyObject]]?, String?) -> Void) {
        
        let session = NSURLSession.sharedSession()
        let urlString = ArgKeys.BASE_URL + FlickrAPI.escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                
                do {
                    let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                        if let totalPages = photosDictionary["pages"] as? Int {
                            /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                            let pageLimit = min(totalPages, 40)
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            FlickrAPI.getImagesFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage) { photos, error in
                                completion_handler(photos, error)
                            }
                        } else {
                            print("Cant find key 'pages' in \(photosDictionary)")
                        }
                    } else {
                        print("Cant find key 'photos' in \(parsedResult)")
                    }
                } catch let error as NSError {
                    print("Failed to parse results: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
    
    static func getImagesFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completion_handler: ([[String: AnyObject]]?, String?) -> Void) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = ArgKeys.BASE_URL + FlickrAPI.escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                do {
                    let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                        var totalPhotosVal = 0
                        if let totalPhotos = photosDictionary["total"] as? String {
                            totalPhotosVal = (totalPhotos as NSString).integerValue
                        }
                        if totalPhotosVal > 0 {
                            if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                let shuffledPics = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(photosArray) as! [[String: AnyObject]]
                                completion_handler(shuffledPics, nil)
                                
                            } else {
                                print("Cant find key 'photo' in \(photosDictionary)")
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                print("No Photos Found. Search Again.")
                            }
                        }
                    } else {
                        print("Cant find key 'photos' in \(parsedResult)")
                    }
                } catch let error as NSError {
                    print("Failed to parse results: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
    
    static func getImageFromURLString(urlString: String, completion_handler: (UIImage?) -> Void) {
        
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        var image: UIImage? = nil
        
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            if let error = downloadError {
                print("Could not complete the request \(error.localizedDescription)")
            } else {
                if let imageData = data {
                    image = UIImage(data: imageData)
                } else {
                    print("No data: \(response?.description)")
                }
            }
            completion_handler(image)
        }
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    static func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        for (key, value) in parameters {
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
}