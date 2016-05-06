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

class AddContactsViewController: UIViewController, UITextFieldDelegate {
    var allContacts = [String: String]()
    var usernameResultsArray = [(username: String, followed: Bool)]()
    var registeredContacts = [(phone: String, name: String, followed: Bool)]()
    var unregisteredContacts = [(phone: String, name: String)]()
    
    var enterFromSetup = false
    var authorized = false
    var usernameSearchResultsMode = false
    var backMethod: (() -> Void)?
    static let CONFIG_CONTACTS = "CONTACTS"
    static let CONFIG_FOLLOWERS = "FOLLOWERS"
    static let CONFIG_FOLLOWING = "FOLLOWING"
    var configurationMode: String?
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var startLoopingButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noContactsView: UIView!
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var searchFieldHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "ContactCell", bundle: nil)
        contactTableView.registerNib(nib, forCellReuseIdentifier: "contactCell")
        contactTableView.rowHeight = UITableViewAutomaticDimension
        contactTableView.estimatedRowHeight = 60.0
        contactTableView.allowsSelection = false
        contactTableView.hidden = true
        contactTableView.tableFooterView = UIView()
        noContactsView.hidden = true
        usernameField.delegate = self
        for family: String in UIFont.familyNames() {
            print("\(family)")
            for names: String in UIFont.fontNamesForFamilyName(family)
            {
                print("== \(names)")
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if enterFromSetup {
            startLoopingButton.hidden = false
            backButton.hidden = true
//            self.navigationItem.setHidesBackButton(true, animated:true)
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    func configureUserList(configurationMode: String, backMethod: () -> Void) {
        self.backMethod = backMethod
        self.configurationMode = configurationMode
    }
    
    override func viewDidAppear(animated: Bool) {
        let appDelegate = AppDelegate.getAppDelegate()
        if let session = appDelegate.getSession(){
            switch configurationMode! {
            case AddContactsViewController.CONFIG_CONTACTS:
                titleLabel.text = "Find Your People"
                attemptLoadContacts()
                searchButton.hidden = false
                usernameField.hidden = false
                break
            case AddContactsViewController.CONFIG_FOLLOWERS:
                titleLabel.text = "Followers"
                fetchFollowers(session)
                searchButton.hidden = true
                usernameField.hidden = true
                searchFieldHeight.constant = 0.0
                break
            case AddContactsViewController.CONFIG_FOLLOWING:
                titleLabel.text = "Following"
                searchFieldHeight.constant = 0.0
                searchButton.hidden = true
                usernameField.hidden = true
                fetchFollowing(session)
                break
            default: break
            }
        } else {
            appDelegate.showError("Login Error", message: "Please ensure you are logged in and try again")
        }
    }
    
    @IBAction func didPressBack(sender: AnyObject) {
        self.backMethod?()
//        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        self.view.endEditing(true)
        // attempt to log in
        fetchUsernameSearchResults()
        return true
    }
    
    @IBAction func didPressSearchUser(sender: AnyObject) {
        // exit the keyboard
        usernameField.endEditing(true)
        // Todo: intercept enter to mean search (soon)
        if usernameSearchResultsMode { // exist username search mode
            usernameSearchResultsMode = false
            searchButton.setImage(UIImage(named: "Search"), forState: .Normal)
            contactTableView.reloadData()
            // maybe clear input (yes)
            return
        }
        // alert user if the
        if (usernameField.text == nil || usernameField.text?.characters.count == 0) {
            AppDelegate.getAppDelegate().showError("Username required", message: "Please enter a username to search")
            return
        }
        fetchUsernameSearchResults()
        // fetch relevant user from server
        // load their information into another dictionary
        // set usernameMode = true
        // in tableViewCell: load contacts by username (same tuple pairing I think (maybe))
    }
    
    private func fetchFollowers(session: String) {
        let params = [
            "session": session,
            "method": "GetFollowers"
        ]
        Alamofire.request(.POST, "https://getkeyframe.com/api/gif_user",
            parameters: params)
            .responseJSON { response in
                API.processResponse(response, onSuccess: self.processFollowerFollowingResponse)
        }
    }
    
    private func fetchFollowing(session: String) {
        let params = [
            "session": session,
            "method": "GetFollowing"
        ]
        Alamofire.request(.POST, "https://getkeyframe.com/api/gif_user",
            parameters: params)
            .responseJSON { response in
                API.processResponse(response, onSuccess: self.processFollowerFollowingResponse)
        }
    }
    
    private func processFollowerFollowingResponse(value: AnyObject) {
        let json = JSON(value)
//        print("\(json)")
        if json["Success"].int == 1 {
            if let followersResults = json["Return"].array {
                usernameResultsArray = [(username: String, followed: Bool)]()
                for follower in followersResults {
                    print("\(follower["Username"].string)")
                    let username = follower["Username"].stringValue
                    let follows = follower["User_follows"].boolValue
                    usernameResultsArray.append((username, follows))
                }
                contactTableView.reloadData()
                contactTableView.hidden = false
                if (usernameResultsArray.count == 0) {
                    // set blank screen
                }
            }
            // returns a dictionary of username : follows
            // create an array of (username, follows)
        } else {
            AppDelegate.getAppDelegate().showError("Search Username Error", message: json["Error"].stringValue)
        }
    }
    
    // load if you have access, else show error
    private func attemptLoadContacts() {
        let contacts: PrivateResource = .Contacts
        proposeToAccess(contacts, agreed: {
            self.loadContacts()
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
    
    // get contacts with accounts from the server
    private func fetchRegisteredContacts(phoneNumbers: [String]) {
        let appDelegate = AppDelegate.getAppDelegate()
        if let session = appDelegate.getSession() {
            do {
                let phoneData = try NSJSONSerialization.dataWithJSONObject(phoneNumbers, options: .PrettyPrinted)
                let phoneJSON = NSString(data: phoneData, encoding: NSUTF8StringEncoding)
                let params = [
                    "session": session,
                    "contacts": phoneJSON as! AnyObject,
                    "method": "GetRegisteredContacts"
                ]
                Alamofire.request(.POST, "https://getkeyframe.com/api/gif_user",
                    parameters: params)
                    .responseJSON { response in
                        API.processResponse(response, onSuccess: self.processRegisteredContactsResponse)
                }
            } catch {
                appDelegate.showError("Address Book Error", message: "Failed to get your friends on Keyframe.")
            }
        } else {
            appDelegate.showError("Login Error", message: "Make sure you're logged in and try again")
        }
    }
    
    private func processRegisteredContactsResponse(value: AnyObject) {
        let json = JSON(value)
        print("\(json)")
        if json["Success"].int == 1 {
            sortContacts(json["Return"].dictionaryValue)
        } else {
            AppDelegate.getAppDelegate().showError("Network Error", message: "Could not fetch contacts.")
        }
    }
    // phoneToFollows = a dictionary of registered phone numbers and whether the user follows them or not
    // TODO: sort contacts into registered and unregistered
    private func sortContacts(phoneToFollows: [String: JSON]) {
        for (phone, name) in allContacts {
            if let userFollows = phoneToFollows[phone]?.boolValue {
                registeredContacts.append((phone, name, userFollows))
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

    private func fetchUsernameSearchResults(){
        if let session = AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "username": usernameField.text!,
                "method": "FindUserToFollowByUsername"
            ]
            Alamofire.request(.POST, "https://getkeyframe.com/api/gif_user",
                parameters: params)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processUsernameSearchResponse)
            }
        } else {
            AppDelegate.getAppDelegate().showError("Login Error", message: "Make sure you're logged in and try again")
        }
    }
    
    private func processUsernameSearchResponse(value: AnyObject) {
        let json = JSON(value)
        print("\(json)")
        if json["Success"].int == 1 {
            let usernameSearchResults = json["Return"].dictionaryValue
            // returns a dictionary of username : follows
            // create an array of (username, follows)
            for (username, followsJSON) in usernameSearchResults {
                usernameResultsArray.append((username, followsJSON.boolValue))
            }
            searchButton.setImage(UIImage(named: "ExitSearch"), forState: .Normal)
            usernameSearchResultsMode = true
            contactTableView.reloadData()
            contactTableView.hidden = false
            if (usernameResultsArray.count == 0) {
                // set blank screen
            }
        } else {
            AppDelegate.getAppDelegate().showError("Search Username Error", message: json["Error"].stringValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Contact Cell Delegate Features
    @IBAction func didPressStartButton(sender: AnyObject) {
        // launch the main storyboard
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let masterViewController = mainStoryboard.instantiateViewControllerWithIdentifier("MasterViewController") as! MasterViewController
        AppDelegate.getAppDelegate().window!.rootViewController = masterViewController
    }
}

extension AddContactsViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if configurationMode == AddContactsViewController.CONFIG_CONTACTS {
            return usernameSearchResultsMode ? usernameResultsArray.count : registeredContacts.count
        } else {
            return usernameResultsArray.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = contactTableView.dequeueReusableCellWithIdentifier("contactCell") as! ContactCell
        cell.delegate = self
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        if configurationMode! == AddContactsViewController.CONFIG_CONTACTS {
            return loadCellContactsMode(cell, indexPath: indexPath)
        } else {
            let (username, following) = usernameResultsArray[indexPath.row]
            cell.loadUsername(username, following: following)
            return cell
        }
    }
    
    private func loadCellContactsMode(cell: ContactCell, indexPath: NSIndexPath) -> UITableViewCell {
        if usernameSearchResultsMode {
            let (username, following) = usernameResultsArray[indexPath.row]
            cell.loadUsername(username, following: following)
        } else {
            let (phone, name, following) = self.registeredContacts[indexPath.row]
            cell.loadContact(phone, name: name, following: following)
        }
        return cell
    }
    
    func tableView( tableView : UITableView,  titleForHeaderInSection section: Int)->String? {
        if configurationMode == AddContactsViewController.CONFIG_CONTACTS {
            return usernameSearchResultsMode ? "Results" : "Friends on Keyframe"
        }
        return nil
    }
}

// Contact Cell methods
extension AddContactsViewController: ContactCellDelegate {
    // if usernameSearchResultsMode followKey = username, else followKey = phone
    // change the methodname called to the server based on whether the user is
    // selecting a username (in username search results mode) or a contact (default, where followKey is phone)
    func followUser(followKey: String, cell: ContactCell) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let methodName = getNameForFollowMethod()
            let keyName = getNameForUserKey()
            let params = [
                "session": session,
                keyName: followKey,
                "method": methodName
            ]
            print("\(params)")
            executeChangeFollowStatus(params, cell: cell)
        }
    }
    
    func unfollowUser(followKey: String, cell: ContactCell) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let methodName = getNameForUnfollowMethod()
            let keyName = getNameForUserKey()
            let params = [
                "session": session,
                keyName: followKey,
                "method": methodName
            ]
            print("\(params)")
            executeChangeFollowStatus(params, cell: cell)
        }
    }
    private func getNameForUserKey() -> String {
        if configurationMode == AddContactsViewController.CONFIG_CONTACTS {
            return usernameSearchResultsMode ? "username" : "phone"
        } else {
            return "username"
        }
    }
    
    private func getNameForFollowMethod() -> String {
        if configurationMode == AddContactsViewController.CONFIG_CONTACTS
            && !usernameSearchResultsMode {
            return "FollowUserByPhone"
        }
        return "FollowUserByUsername"
    }
    
    private func getNameForUnfollowMethod() -> String {
        if configurationMode == AddContactsViewController.CONFIG_CONTACTS
            && !usernameSearchResultsMode {
            return "UnfollowUserByPhone"
        }
        return "UnfollowUserByUsername"
    }
    
    private func executeChangeFollowStatus(params: [String : String], cell: ContactCell) {
        Alamofire.request(.POST, "https://getkeyframe.com/api/gif_user",
            parameters: params)
            .responseJSON { response in
                self.processChangeFollowStatusRepsonse(response, cell: cell, params: params)
        }
    }
    
    private func processChangeFollowStatusRepsonse(response: Response<AnyObject, NSError>, cell: ContactCell, params: [String: String]) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showError("Connection Error", message: "Failed to record follow/unfollow")
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            print("\(json)")
            if json["Success"].int == 1 {
                // update the table view data and cell
                let nowFollowing = params["method"]!.hasPrefix("Follow")
                updateData(params, nowFollowing: nowFollowing)
                cell.following = nowFollowing
            } else {
                AppDelegate.getAppDelegate().showError("Follow Error", message: "Failed to record follow/unfollow")
            }
        }
    }
    
    private func updateData(params: [String : String], nowFollowing: Bool) {
        if configurationMode == AddContactsViewController.CONFIG_CONTACTS {
            updateContactsData(params, nowFollowing: nowFollowing)
        } else {
            let username = params["username"]!
            updateUsernameResultsData(username, nowFollowing: nowFollowing)
        }
    }
    
    private func updateContactsData(params: [String : String], nowFollowing: Bool) {
        if (usernameSearchResultsMode) {
            let username = params["username"]!
            updateUsernameResultsData(username, nowFollowing: nowFollowing)
        } else {
            let phone = params["phone"]!
            updateContactsData(phone, nowFollowing: nowFollowing)
        }
    }
    
    private func updateUsernameResultsData(username: String, nowFollowing: Bool) {
        for i in 0...usernameResultsArray.count-1 {
            let (array_username, _) = usernameResultsArray[i]
            if array_username == username {
                usernameResultsArray[i] = (username, nowFollowing)
            }
        }
        contactTableView.reloadData()
    }
    
    private func updateContactsData(phone: String, nowFollowing: Bool) {
        for i in 0...registeredContacts.count-1 {
            let (array_phone, name, _) = registeredContacts[i]
            if array_phone == phone {
                registeredContacts[i] = (phone, name, nowFollowing)
            }
        }
        contactTableView.reloadData()
    }
}