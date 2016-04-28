//
//  API.swift
//  chakula
//
//  Created by Agree Ahmed on 7/25/15.
//  Copyright © 2015 org.rhye. All rights reserved.
//

import Foundation
import Alamofire

protocol APICallback {
    func resultDidReturn(result: NSDictionary, method: String)
    func errorDidReturn(error: ErrorType, method: String)
}

class API {
    class func processResponse(response: Response<AnyObject, NSError>, onSuccess: (AnyObject) -> Void) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showError("Connection Error", message: "Check your internet connection and please try again.")
            return
        }
        if let value: AnyObject = response.result.value {
            onSuccess(value)
        } else {
            AppDelegate.getAppDelegate().showError("Network Error", message: "There was an error handling your request.")
        }
    }

    class func processResponse(response: Response<AnyObject, NSError>, onSuccess: (AnyObject) -> Void, onFailure: () -> Void) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            onFailure()
            AppDelegate.getAppDelegate().showError("Connection Error", message: "Check your internet connection and please try again.")
            return
        }
        if let value: AnyObject = response.result.value {
            onSuccess(value)
        } else {
            onFailure()
        }
    }

    
}

//class API: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {

//    static let URL = "https://qa.yaychakula.com/api/",
//    URL_GIF = URL + "gif",
//    RESULT_BODY = "Return",
//    RESULT_ERROR = "Error",
//    RESULT_SUCCESS = "Success"
//    
//    static func buildRequest(url: String, method: String, postString: String) -> NSMutableURLRequest {
//        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
//        request.HTTPMethod = "POST"
//        let composedPost = "method=\(method)&" + postString
//        request.HTTPBody = composedPost.dataUsingEncoding(NSUTF8StringEncoding)
//        return request
//    }
//    
//    static func newSession() -> NSURLSession{
//        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
//        return NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
//    }
//    
//    
//    func post(request: NSMutableURLRequest!, callback: APICallback, method: String) {
//        let task = API.newSession().dataTaskWithRequest(request){
//            data, response, error in
//            if error != nil {
//                callback.errorDidReturn(error!, method: method)
//                return
//            }
//            do {
//                if let jsonResult =  try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
//                    print("calling callback")
//                    callback.resultDidReturn(jsonResult, method: method)
//                }
//            } catch { // TODO: catch error
//                callback.errorDidReturn(error, method: method)
//            }
//        }
//        task.resume()
//    }
//    
//    func URLSession(session: NSURLSession,
//        task: NSURLSessionTask,
//        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
//        completionHandler: (NSURLSessionAuthChallengeDisposition,
//        NSURLCredential?) -> Void) {
//            completionHandler(
//                NSURLSessionAuthChallengeDisposition.UseCredential,
//                NSURLCredential(forTrust:
//                    challenge.protectionSpace.serverTrust!))
//    }
//    
//    func URLSession(session: NSURLSession,
//        task: NSURLSessionTask,
//        willPerformHTTPRedirection response: NSHTTPURLResponse,
//        newRequest request: NSURLRequest,
//        completionHandler: (NSURLRequest?) -> Void) {
//            let newRequest : NSURLRequest? = request
//            //            print(newRequest?.description)
//            completionHandler(newRequest)
//    }
//    
//    struct USER {
//        static let SESSION_TOKEN = "Session_token",
//        FIRST_NAME = "First_name",
//        LAST_NAME = "Last_name",
//        ID = "Id",
//        Phone = "Phone"
//        
//    }
//    struct TRUCK {
//        static let ID = "Truck_id"
//    }
//    struct MENU_ITEM {
//        static let  MENU_ID = "Id",
//        ORDER_ID = "item_id",
//        NAME = "Name",
//        PIC_URL = "Pic_url",
//        QUANT = "quantity",
//        PRICE = "Price",
//        DESC = "Description",
//        LIST_OPTIONS_MENU = "ListOptions",
//        LIST_OPTIONS_ORDER = "listoptions",
//        TOGGLE_OPTIONS_MENU = "ToggleOptions",
//        TOGGLE_OPTIONS_ORDER = "toggleoptions"
//    }
// }
