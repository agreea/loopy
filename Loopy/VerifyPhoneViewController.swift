//
//  VerifyPhoneViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/8/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class VerifyPhoneViewController: UIViewController {

    @IBOutlet weak var codeField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(false, animated:true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressVerify(sender: AnyObject) {
        if codeField.text!.characters.count != 4 {
            showErrorMessage("Phone number must be 4 digits long")
            return
        }
        verifyPhone()
    }
    
    @IBAction func didPressSendNewCode(sender: AnyObject) {
        sendNewCode()
    }
    
    private func sendNewCode() {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        if let session = appDelegate.getSession() {
            let parameters = [
                "method": "SendNewPin",
                "session": session
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                parameters: parameters)
        }
    }
    
    private func verifyPhone() {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        
        if let session = appDelegate.getSession() {
            let parameters = [
                "method": "verifyPhone",
                "session": session,
                "pin": codeField.text!
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                parameters: parameters)
                .responseJSON { response in
                    self.processVerifyResponse(response)
            }
        }
    }
    
    private func processVerifyResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"].int == 1,
                let appDelegate =
                UIApplication.sharedApplication().delegate as? AppDelegate {
                if appDelegate.setPhoneVerified() {
                    performSegueWithIdentifier("PhoneVerified", sender: nil)
                } else {
                    showErrorMessage("Could not log in user. Please unininstall this shit app.")
                }
            } else {
                print("JSON Casting failed")
                showErrorMessage(json["Error"].string!)
            }
        }
    }

    private func showErrorMessage(message: String){
        // show error
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
