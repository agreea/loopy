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
    
    @IBOutlet weak var revealPasswordButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    var registered = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.delegate = self
        usernameField.addTarget(self, action: #selector(SignupViewController.usernameFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)


        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setupBackground()
    }
    
    @IBAction func didPressBack(sender: AnyObject) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func usernameFieldDidChange(textField: UITextField) {
        if isUserNameDirty(){
            print("found a bad character")
            setUsernamefieldError()
        } else {
            setUsernamefieldOkay()
        }
    }
    
    private func setUsernamefieldError() {
        // initial flash
        // drop down to a dull red
        // reveal username error text
    }
    
    private func setUsernamefieldOkay() {
        // drop down to white
    }
    private func setupBackground() {
//        view.backgroundColor = UIColor.clearColor()
//        let gl = CAGradientLayer()
//        gl.colors = [UIColor(netHex: 0x29FC1E).CGColor, UIColor(netHex: 0x006D4C).CGColor]
//        gl.locations = [ 0.0, 1.0]
//        let backgroundLayer = gl
//        backgroundLayer.frame = view.frame
//        view.layer.insertSublayer(backgroundLayer, atIndex: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.

    }
    // toggle secure text entry on the password field 
    // and change the image in the reveal password button
    @IBAction func didPressRevealPassword(sender: AnyObject) {
        passwordField.secureTextEntry =
            !passwordField.secureTextEntry
        let imageFile = passwordField.secureTextEntry ? "PasswordSecure" : "PasswordRevealed"
        revealPasswordButton.setImage(UIImage(named: imageFile), forState: UIControlState.Normal)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
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
        register()
    }
    
    private func isUserNameDirty() -> Bool {
        let username = usernameField!.text!
        return username.containsEmoji || username.containsRegex("\\W")
    }
    
    private func showUsernameMissing() {
        AppDelegate.getAppDelegate().showErrorFromController("Sign Up Error", message: "Username cannot be empty", viewController: self)
        print("username missing")
    }
    
    private func showUsernameDirty() {
        AppDelegate.getAppDelegate().showErrorFromController("Sign Up Error", message: "Username can only contain letters (A-z), numbers (0-9) and emojis", viewController: self)
    }
    
    private func showPasswordMissing() {
        AppDelegate.getAppDelegate().showErrorFromController("Sign Up Error", message: "Password can't be empty", viewController: self)
    }
    
    private func register() {
        print("registering")
        let parameters = [
            "method": "Create",
            "username": usernameField!.text!,
            "password": passwordField!.text!
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
            AppDelegate.getAppDelegate().showErrorFromController("Connection Error", message: "Failed to register. Make sure you're online.", viewController: self)
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
                    registered = true
                    performSegueWithIdentifier("RegisterComplete", sender: nil)
                } else {
                    AppDelegate.getAppDelegate().showErrorFromController("Sign Up Error", message: "Failed to sign up", viewController: self)
                }
            } else {
                print("JSON Casting failed")
            }
        }
    }
    override func shouldPerformSegueWithIdentifier(identifier: String,sender: AnyObject?) -> Bool {
        return registered
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
