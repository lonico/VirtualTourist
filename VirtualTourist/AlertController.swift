//
//  AlertController.swift
//  OnTheMap
//
//  Created by Laurent Nicolas on 9/7/15.
//  Copyright (c) 2015 Laurent Nicolas. All rights reserved.
//

import UIKit

struct AlertController {
    
    struct Alert {
        let msg: String?
        let title: String?
        let handler: ((UIAlertAction) -> Void)?
        
        init(msg: String?, title: String?, handler: ((UIAlertAction) -> Void)? = nil) {
            self.msg = msg
            self.title = title
            self.handler = handler
        }
        
        func showAlert(vc: UIViewController) -> Void {
            
            var valid_title = title
            if valid_title == nil {
                valid_title = AlertTitle.Generic
            }
            let alertController = UIAlertController(title: valid_title, message: msg, preferredStyle: .Alert)
            var cancelAction: UIAlertAction
            if handler == nil {
                cancelAction = UIAlertAction(title: AlertActionTitle.Dismiss, style: UIAlertActionStyle.Cancel, handler: nil)
            } else {
                cancelAction = UIAlertAction(title: AlertActionTitle.Dismiss, style: UIAlertActionStyle.Cancel) { action in
                    self.handler!(action)
                }
            }
            alertController.addAction(cancelAction)
            vc.presentViewController(alertController, animated: true, completion: nil)
        }
        
        func dispatchAlert(vc: UIViewController) -> Void {
            
            dispatch_async(dispatch_get_main_queue()) {
            self.showAlert(vc)
            }
        }
    }
    
    struct AlertTitle {
        
        static let Generic = "Alert"
        static let InternalError = "Internal error"
        
        static let RefreshError = "Refresh error"
        static let OpenURLError = "Failed to open URL"
        static let MissingURLError = "Empty URL string"
        static let MissingLocationError = "Empty location"
        static let Details = "Details"
        static let Success = "Success"
        
    }
    
    struct AlertActionTitle {
        
        static let Dismiss = "Dismiss"
    }
}