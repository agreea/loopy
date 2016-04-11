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
        print("Navigation bar hidden: \(self.navigationController?.navigationBarHidden)")
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
    
    func attemptLogin() {
        var canLogin = true
        if username == nil || username!.characters.count == 0 {
            showUsernameMissing()
            canLogin = false
        }
        if password == nil || password!.characters.count == 0 {
            showPasswordMissing()
            canLogin = false
        }
        if canLogin {
            login()
        }
    }
    
    private func showUsernameMissing() {
        print("username missing")
    }
    
    private func showPasswordMissing() {
        print("password missing")
    }
    
    private func login() {
        let parameters = [
            "method": "Login",
            "username": username!,
            "password": password!
        ]
        Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
            parameters: parameters)
            .responseJSON { response in
                self.processLoginResponse(response)
        }
    }
    
    private func processLoginResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
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
                    launchMainStoryBoard()
                } else {
                    showErrorMessage("Could not log in user. Please unininstall this shit app.")
                }
            } else {
                print("JSON Casting failed")
                showErrorMessage(json["Error"].string!)
            }
        }
    }
    
    private func launchMainStoryBoard() {
        print("Launching main story board")
        // otherwise launch the splash scene
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let masterViewController = mainStoryboard.instantiateViewControllerWithIdentifier("MasterViewController") as! MasterViewController
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window!.rootViewController = masterViewController
    }

    private func showErrorMessage(errorMessage: String) {
        
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
