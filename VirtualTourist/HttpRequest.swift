//
//  HttpRequest.swift
//  VirtualTourist
//
//  Created by Laurent Nicolas on 10/4/15.
//  Copyright © 2015 Laurent Nicolas. All rights reserved.
//

import Foundation
import UIKit

class HttpRequest {
    
    var session = NSURLSession.sharedSession()
    
    // MARK: Only GET method is needed
    
    func sendGetRequest(urlString: String, methodArguments: [String : AnyObject]?, completion_handler: (NSData?, NSError?) -> Void) {
        
        let urlStringWithParm = urlString + HttpRequest.escapedParameters(methodArguments)
        let url = NSURL(string: urlStringWithParm)!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) { data, response, error in
            completion_handler(data, error)
        }
        
        task.resume()
    }
    
    static func sharedInstance() -> HttpRequest {
        
        struct Singleton {
            static var instance = HttpRequest()
        }
        return Singleton.instance
    }
    
    // MARK: utilities
    
    // Like NSData but with asynchronous completions handler
    func getImageFromURLString(urlString: String, completion_handler: (UIImage?, String?) -> Void) {
        
        sendGetRequest(urlString, methodArguments: nil) { data, error in
            
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

    // Helper function: Given a dictionary of parameters, convert to a string for a url
    static func escapedParameters(parameters: [String : AnyObject]?) -> String {
        
        var urlVars = [String]()
        if parameters != nil {
            for (key, value) in parameters! {
                /* Make sure that it is a string value */
                let stringValue = "\(value)"
                /* Escape it */
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                /* Append it */
                urlVars += [key + "=" + "\(escapedValue!)"]
            }
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}