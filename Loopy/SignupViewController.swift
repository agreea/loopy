//
//  SignupViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/7/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var revealPasswordButton: NSLayoutConstraint!
    
    @IBOutlet weak var passwordField: UITextField!
    var username: String?
    var password: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressRevealPassword(sender: AnyObject) {
        passwordField.secureTextEntry =
            !passwordField.secureTextEntry
    }
    func usernameDidChange(textField: UITextField) {
        username = textField.text
    }

    func passwordDidChange(textField: UITextField) {
        password = textField.text
    }

    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        textField.resignFirstResponder()
        self.view.endEditing(true)
        // attempt to log in
        attemptRegister()
        return true
    }
    
    @IBAction func didPressRegister(sender: AnyObject) {
        attemptRegister()
    }
    
    private func attemptRegister() {
        var canRegister = true
        if username == nil || username!.characters.count == 0 {
            showUsernameMissing()
            canRegister = false
        }
        if password == nil || password!.characters.count == 0 {
            showPasswordMissing()
            canRegister = false
        }
        if canRegister {
            register()
        }
    }
    
    private func showUsernameMissing() {
        print("username missing")
    }
    
    private func showPasswordMissing() {
        print("password missing")
    }
    
    private func register() {
        let parameters = [
            "method": "Create",
            "username": username!,
            "password": password!
        ]
        Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
            parameters: parameters)
            .responseJSON { response in
                self.processRegisterResponse(response)
        }
    }
    
    private func processRegisterResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"].int == 1,
                let username = json["Return"]["Username"].string,
                let session = json["Return"]["Session_token"].string,
                let userId = json["Return"]["Id"].int,
                let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                if appDelegate.saveUserData(userId, session: session, username: username) {
                    performSegueWithIdentifier("RegisterComplete", sender: nil)
                } else {
                    showErrorMessage("Could not register user.")
                }
            } else {
                print("JSON Casting failed")
                showErrorMessage(json["Error"].string!)
            }
        }
    }
    
    private func showErrorMessage(message: String) {
        
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
