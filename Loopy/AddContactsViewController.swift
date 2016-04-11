//
//  AddContactsViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/8/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Contacts
import Alamofire
import SwiftyJSON
import Proposer

class AddContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ContactCellDelegate {
    var allContacts = [String: String]()
    var phoneToUsername = [String: JSON]()
    var registeredContacts = [(phone: String, name: String, followed: Bool)]()
    var unregisteredContacts = [(phone: String, name: String)]()
    var enterFromSetup = false
    var authorized = false
    @IBOutlet weak var startLoopingButton: UIButton!
    @IBOutlet weak var noContactsView: UIView!
    @IBOutlet weak var contactTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "ContactCell", bundle: nil)
        contactTableView.registerNib(nib, forCellReuseIdentifier: "contactCell")
        contactTableView.rowHeight = UITableViewAutomaticDimension
        contactTableView.estimatedRowHeight = 60.0
        contactTableView.allowsSelection = false
        contactTableView.hidden = true
        noContactsView.hidden = true
    }

    private func stripPhoneNumber(phoneString: String) -> String {
        let stringArray = phoneString.componentsSeparatedByCharactersInSet(
            NSCharacterSet.decimalDigitCharacterSet().invertedSet)
        var digitsOnly = stringArray.joinWithSeparator("")
        let firstChar = digitsOnly[digitsOnly.startIndex]
        if firstChar == "1" || firstChar == "0" {
            digitsOnly = String(digitsOnly.characters.dropFirst())
        }
        return digitsOnly
    }
    override func viewWillAppear(animated: Bool) {
        if enterFromSetup {
            startLoopingButton.hidden = false
//            self.navigationItem.setHidesBackButton(true, animated:true)
        }
        checkContactsAccess()
    }
    override func viewDidAppear(animated: Bool) {
        if authorized {
            loadContacts()
        }
    }
    private func checkContactsAccess() {
        let contacts: PrivateResource = .Contacts
        proposeToAccess(contacts, agreed: {
            self.authorized = true
            }, rejected: {
                print("Shut down")
                AppDelegate.getAppDelegate().showSettingsAlert("Allow Access to Contacts",
                    message: "Allow Loopy to access your contacts so you can find your friends.")
        })
    }

    // get contacts from phone and fetch the registered ones from the server
    private func loadContacts() {
        var phoneNumbers = [String]()
        let contacts = AppDelegate.getAppDelegate().getAllContacts()
        for contact in contacts {
            phoneNumbers += self.parsePhoneNumbersForContact(contact)
        }
        self.fetchRegisteredContacts(phoneNumbers)
    }
    
    // for each phone number on file,
    // pair phone number with contact name in the member dictionary
    private func parsePhoneNumbersForContact(contact: CNContact) -> [String] {
        let fullName = contact.givenName + " " + contact.familyName
        var phoneNumbersForContact = [String]()
        for phoneNumber in contact.phoneNumbers {
            if let phoneVal = phoneNumber.value as? CNPhoneNumber{
                let phoneString = phoneVal.stringValue
                let strippedNumber = self.stripPhoneNumber(phoneString)
                allContacts[strippedNumber] = fullName
                phoneNumbersForContact.append(strippedNumber)
            }
        }
        return phoneNumbersForContact
    }
    
    // get contacts with accounts from the server
    private func fetchRegisteredContacts(phoneNumbers: [String]) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            do {
                let phoneData = try NSJSONSerialization.dataWithJSONObject(phoneNumbers, options: .PrettyPrinted)
                let phoneJSON = NSString(data: phoneData, encoding: NSUTF8StringEncoding)
                let params = [
                    "session": session,
                    "contacts": phoneJSON as! AnyObject,
                    "method": "GetRegisteredContacts"
                ]
                Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                    parameters: params)
                    .responseJSON { response in
                        self.processRegisteredContactsResponse(response)
                }
            } catch {
                
            }
        } else {
            AppDelegate.getAppDelegate().showError("Login Error", message: "Make sure you're logged in and try again")
        }
    }
    
    private func processRegisteredContactsResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            print("\(json)")
            if json["Success"].int == 1 {
                phoneToUsername = json["Return"].dictionaryValue
                
            } else {
                showErrorMessage("Could not register user.")
            }
        }
        sortContacts()
    }
    
    // sort contacts into registered and unregistered
    private func sortContacts() {
        for (phone, name) in allContacts {
            if let user = phoneToUsername[phone] {
                registeredContacts.append((phone, name, user["Follows"].boolValue))
            } else {
                // TODO: implement unregistered contacts experience
                unregisteredContacts.append((phone, name))
            }
        }
        if registeredContacts.count == 0 {
            noContactsView.hidden = false
        }
        self.contactTableView.reloadData()
        contactTableView.hidden = false
        print("Should be up, registered contacts:")
        print("\(registeredContacts)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(registeredContacts.count)")
        return registeredContacts.count
    }

    private func showErrorMessage(message: String){
        // show error
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = contactTableView.dequeueReusableCellWithIdentifier("contactCell") as! ContactCell
        cell.delegate = self
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero

        print("got cell")
        var phone = ""
        var name = ""
        var following = false
        if (indexPath.section==0) {
            (phone, name, following) = self.registeredContacts[indexPath.row]
        } else {
            (phone, name) = self.unregisteredContacts[indexPath.row]
        }
        cell.loadContact(phone, name: name, following: following)
        return cell
    }
    
    // Contact Cell Delegate Features
    
    func followUser(phone: String, cell: ContactCell) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "contacts": phone,
                "method": "FollowUserByPhone"
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                parameters: params)
                .responseJSON { response in
                    self.processFollowRepsonse(response, cell: cell)
            }
        }
    }
    
    private func processFollowRepsonse(response: Response<AnyObject, NSError>, cell: ContactCell) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            print("\(json)")
            if json["Success"].int == 1 {
                cell.following = true
            } else {
                showErrorMessage("Failed to follow user.")
            }
        }
    }
    
    func unfollowUser(phone: String, cell: ContactCell) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "contacts": phone,
                "method": "unfollowUserByPhone"
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                parameters: params)
                .responseJSON { response in
                    self.processUnfollowRepsonse(response, cell: cell)
            }
        }
    }
    
    private func processUnfollowRepsonse(response: Response<AnyObject, NSError>, cell: ContactCell) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            print("\(json)")
            if json["Success"].int == 1 {
                cell.following = false
            } else {
                showErrorMessage("Connection failed.")
            }
        }
    }
    
    @IBAction func didPressStartButton(sender: AnyObject) {
        // launch the main storyboard
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let masterViewController = mainStoryboard.instantiateViewControllerWithIdentifier("MasterViewController") as! MasterViewController
        AppDelegate.getAppDelegate().window!.rootViewController = masterViewController
    }


}
