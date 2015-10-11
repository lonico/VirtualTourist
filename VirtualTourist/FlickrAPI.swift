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
    
    struct ArgValues {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "47ab5778cf6752cd2eb7339c04b48d6d"
        static let EXTRAS = "url_t,url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
    }
    
    static func getImagesFromFlickrForCoordinate(coordinate: CLLocationCoordinate2D, completion_handler: ([(String?, String, String)]?, String?) -> Void) {
        
        let searchMethodArguments = [
            "bbox": FlickrAPI.createBoundingBoxString(coordinate),
        ]
        
        FlickrAPI.getImagesFromFlickrBySearch(searchMethodArguments) { photos, error in
            if let errorStr = error {
                print("Error in getImagesFromFlickrBySearch: \(errorStr)")
                completion_handler(nil, errorStr)
            } else if let photos = photos {
                print(photos.count) // TODO:
                var imageURLs = [(String?, String, String)]()
                for photo in photos {
                    let photoDictionary = photo //as [String: AnyObject]
                    
                    let photoTitle = photoDictionary["title"] as? String
                    if let imageUrlTString = photoDictionary["url_t"] as? String {
                        if let imageUrlMString = photoDictionary["url_m"] as? String {
                            imageURLs.append((photoTitle, imageUrlTString, imageUrlMString))
                        }
                    }
                }
                completion_handler(imageURLs, nil)
            } else {
                let errorStr = "No picture found"
                print(errorStr)
                completion_handler(nil, errorStr)
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

        let urlString = ArgValues.BASE_URL
        var searchMethodArguments = [
            "method": ArgValues.METHOD_NAME,
            "api_key": ArgValues.API_KEY,
            "safe_search": ArgValues.SAFE_SEARCH,
            "format": ArgValues.DATA_FORMAT,
            "nojsoncallback": ArgValues.NO_JSON_CALLBACK
        ] as [String : AnyObject]
        
        for (key, value) in methodArguments {
            searchMethodArguments[key] = value
        }
    
        HttpRequest.sharedInstance().sendGetRequest(urlString, methodArguments: searchMethodArguments) { data, error in
            
            var photosDict: [[String: AnyObject]]? = nil
            var errorStr: String? = nil
            if let error = error {
                errorStr = "Could not complete the request:\n \(error.localizedDescription)"
                print(errorStr)
                completion_handler(photosDict, errorStr)
            } else {
                do {
                    let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                        if let totalPages = photosDictionary["pages"] as? Int {
                            /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                            let pageLimit = min(totalPages, 40)
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            FlickrAPI.getImagesFromFlickrBySearchWithPage(searchMethodArguments, pageNumber: randomPage) { photos, error in
                                
                                if let error = error {
                                    errorStr = "Could not complete the request:\n \(error)"
                                    print(errorStr)
                                } else if let photos = photos {
                                    photosDict = photos
                                } else {
                                    errorStr = "No data, and no error!"
                                    print(errorStr)
                                }
                                completion_handler(photosDict, errorStr)
                            }
                        } else {
                            errorStr = "Cant find key 'pages' in \(photosDictionary)"
                            print(errorStr)
                            completion_handler(photosDict, errorStr)
                        }
                    } else {
                        errorStr = "Can't find key 'photos' in \(parsedResult)"
                        print(errorStr)
                        completion_handler(photosDict, errorStr)
                    }
                } catch let error as NSError {
                    errorStr = "Failed to parse results: \(error.localizedDescription)"
                    print(errorStr)
                    completion_handler(photosDict, errorStr)
                }
            }
        }
    }
    
    static func getImagesFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completion_handler: ([[String: AnyObject]]?, String?) -> Void) {
        
        /* Add the page to the method's arguments */
        var argDictionary = methodArguments
        argDictionary["page"] = pageNumber
        argDictionary["extras"] = ArgValues.EXTRAS
        let urlString = ArgValues.BASE_URL
        HttpRequest.sharedInstance().sendGetRequest(urlString, methodArguments: argDictionary) { data, error in

            var shuffledPics: [[String: AnyObject]]? = nil
            var errorStr: String? = nil
            if let error = error {
                errorStr = "Could not complete the request \(error)"
                print(errorStr)
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
                                shuffledPics = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(photosArray) as? [[String: AnyObject]]
                            } else {
                                errorStr = "Cant find key 'photo' in \(photosDictionary)"
                                print(errorStr)
                            }
                        } else {
                            errorStr = "No Photos Found. Search Again."
                            print(errorStr)
                        }
                    } else {
                        errorStr = "Can't find key 'photos' in \(parsedResult)"
                        print(errorStr)
                    }
                } catch let error as NSError {
                    errorStr = "Failed to parse results: \(error.localizedDescription)"
                    print(errorStr)
                }
            }
            completion_handler(shuffledPics, errorStr)
        }
    }
    
    static func getImageFromURLString(urlString: String, completion_handler: (UIImage?, String?) -> Void) {
        
        HttpRequest.sharedInstance().sendGetRequest(urlString, methodArguments: nil) { data, error in
            
            var image: UIImage? = nil
            var errorStr: String? = nil
            if let error = error {
                errorStr = "Could not complete the request:\n \(error.localizedDescription)"
                print(errorStr)
            } else {
                if let imageData = data {
                    image = UIImage(data: imageData)
                } else {
                    errorStr = "No data for: \(urlString)"
                    print(errorStr)
                }
            }
            completion_handler(image, errorStr)
        }
    }
}