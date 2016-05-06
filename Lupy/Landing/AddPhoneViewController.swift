//
//  AddPhoneViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/8/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class AddPhoneViewController: UIViewController {

    @IBOutlet weak var phoneTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated:true)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func didPressSendCode(sender: AnyObject) {
        if phoneTextField.text == nil || phoneTextField.text!.characters.count != 10 {
            // alert
            AppDelegate.getAppDelegate().showErrorFromController("Add Phone Error", message: "Phone number must be 10 digits long", viewController: self)
        } else {
            addPhone()
        }
    }
    
    private func addPhone() {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        if let session = appDelegate.getSession() {
            let parameters = [
                "method": "UpdatePhone",
                "session": session,
                "phone": phoneTextField.text!
            ]
            Alamofire.request(.POST, "https://getkeyframe.com/api/gif_user",
                parameters: parameters)
                .responseJSON { response in
                    self.processAddPhoneResponse(response)
            }
        } else {
            AppDelegate.getAppDelegate().showErrorFromController("Authentication Error", message: "Make sure you're logged in", viewController: self)
        }
    }
    
    private func processAddPhoneResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showErrorFromController("Connection Error", message: "Failed to add phone number", viewController: self)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"].int == 1 {
                performSegueWithIdentifier("PhoneAdded", sender: nil)
            } else {
                print("in that fuckin else where u @?")
                AppDelegate.getAppDelegate().showErrorFromController("Add Phone Error", message: json["Error"].stringValue, viewController: self)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
