//
//  LoginViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/7/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var username: String?
    var password: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameField.addTarget(self, action: #selector(LoginViewController.usernameDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        passwordField.addTarget(self, action: #selector(LoginViewController.passwordDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        passwordField.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = false
    }

    func usernameDidChange(textField: UITextField) {
        //your code
        username = textField.text
    }
    
    func passwordDidChange(textField: UITextField) {
        password = textField.text
    }
    
    // called only by the password textField
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        self.view.endEditing(true)
        // attempt to log in
        attemptLogin()
        return true
    }
    
    
    @IBAction func didPressBackButton(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPressLoginButton(sender: AnyObject) {
        attemptLogin()
    }
    func attemptLogin() {
        print("attempting login")
        if passwordField!.text!.characters.count == 0 {
            showPasswordMissing()
            return
        }
        if usernameField!.text!.characters.count == 0 {
            showUsernameMissing()
            return
        } else if isUserNameDirty() {
            showUsernameDirty()
            return
        }
        login()
    }
    
    private func isUserNameDirty() -> Bool {
        let username = usernameField!.text!
        return username.containsEmoji || username.containsRegex("\\W")
    }
    
    private func showUsernameMissing() {
        AppDelegate.getAppDelegate().showErrorFromController("Login Error", message: "Username cannot be empty", viewController: self)
        print("username missing")
    }
    
    private func showUsernameDirty() {
        AppDelegate.getAppDelegate().showErrorFromController("Login Error", message: "Username can only contain letters (A-z), numbers (0-9) and emojis", viewController: self)
    }
    
    private func showPasswordMissing() {
        AppDelegate.getAppDelegate().showErrorFromController("Login Error", message: "Password can't be empty", viewController: self)
    }

    private func login() {
        let parameters = [
            "method": "Login",
            "username": username!,
            "password": password!
        ]
        Alamofire.request(.POST, API.ENDPOINT_USER,
            parameters: parameters)
            .responseJSON { response in
                self.processLoginResponse(response)
        }
    }
    
    private func processLoginResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showErrorFromController("Connection Error", message: "Make sure you're online", viewController: self)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            print("json: ")
            print("\(json)")
            if json["Success"].int == 1,
                let username = json["Return"]["Username"].string,
                let session = json["Return"]["Session_token"].string,
                let userId = json["Return"]["Id"].int,
                let appDelegate =
                UIApplication.sharedApplication().delegate as? AppDelegate {
                print("Attempting to save data")
                if appDelegate.saveUserData(userId, session: session, username: username) {
                    usernameField.resignFirstResponder()
                    passwordField.resignFirstResponder()
                    launchMainStoryBoard()
                } else {
                    AppDelegate.getAppDelegate().showErrorFromController("Login Error", message: "Failed to log in user", viewController: self)
                }
            } else {
                print("JSON Casting failed")
                AppDelegate.getAppDelegate().showErrorFromController("Login Error", message: "Failed to log in user", viewController: self)
            }
        }
    }
    
    private func launchMainStoryBoard() {
        print("Launching main story board")
        // otherwise launch the splash scene
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let masterViewController = mainStoryboard.instantiateViewControllerWithIdentifier("TabBarViewController") as! TabBarViewController
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window!.rootViewController = masterViewController
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
