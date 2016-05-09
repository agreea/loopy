//
//  MyLoopsViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/13/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ProfileViewController: FeedViewController {
    var username: String?
    var userId: Int? // DO NOT CONFUSE THIS WITH "id", which is always the current user's id
    var followers: [JSON]?
    var following: [JSON]?
    var posts: [JSON]?
    var likes: [JSON]?
    var _isFollowing = false
    var isFollowing: Bool {
        get {
            return _isFollowing
        }
        set(newValue){
            _isFollowing = newValue
            if !isSelf() {
                print("Set following!")
                let imageName = _isFollowing ? "FollowsUser" : "AddUser"
                rightButtonNav.setImage(UIImage(named: imageName), forState: .Normal)
            } else {
                print("Was self!!")
            }
        }
    }
    var backButtonMethod: (() -> Void)?
    private var loadedData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userNib = UINib(nibName: "MyLoopsUserCell", bundle: nil)
        feedView.registerNib(userNib, forCellReuseIdentifier: "myLoopsUserCell")
        leftButtonNav.setImage(UIImage(named: "NavbarBack"), forState: .Normal)
        feedView.estimatedRowHeight = view.frame.width * 1.25 + 60
        feedView.rowHeight = UITableViewAutomaticDimension
        navBarVanishes = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configProfileByUsername(username: String, backButtonMethod: (() -> Void)?) {
        if backButtonMethod == nil {
//            self.leftButtonNav.hidden = true
        } else {
            self.backButtonMethod = backButtonMethod
        }
        self.username = username
    }
    
    func configProfileByUserId(userId: Int, backButtonMethod: (() -> Void)?) {
        if backButtonMethod == nil {
//            self.leftButtonNav.hidden = true
        } else {
            self.backButtonMethod = backButtonMethod
        }
        self.userId = userId
    }

    override func viewWillAppear(animated: Bool) {
        titleNav.font = UIFont(name: "PierSans", size: CGFloat(20.0))
        if loadedData {
            return
        }
        if userId != nil {
            loadProfileByUserId(userId!)
        } else if username != nil {
            loadProfileByUsername(username!)
        }
        leftButtonNav.hidden = backButtonMethod == nil
        //        attemptLoadFeed()
    
    }
    
    // loads username, followers (Array), and following (array)
    func loadProfileByUserId(userId: Int) {
        titleNav.hidden = true
        rightButtonNav.hidden = true
        if let session = AppDelegate.getAppDelegate().getSession() {
            let parameters = [
                "method": "GetProfileByUserId",
                "session": session,
                "userId": "\(userId)"
            ]
            Alamofire.request(.POST, API.ENDPOINT_USER,
                parameters: parameters)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processGetUserDataResponse)
            }
        }
    }
    
    func loadProfileByUsername(username: String) {
        titleNav.hidden = true
        rightButtonNav.hidden = true
        if let session = AppDelegate.getAppDelegate().getSession() {
            let parameters = [
                "method": "GetProfileByUsername",
                "session": session,
                "username": "\(username)"
            ]
            Alamofire.request(.POST, API.ENDPOINT_USER,
                parameters: parameters)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processGetUserDataResponse)
            }
        }
    }
    
    private func processGetUserDataResponse(value: AnyObject) {
        let json = JSON(value)
        if json["Success"] == 1 {
            print("\(json)")
            username = json["Return","Username"].string
            followers = json["Return", "Followers"].array
            following = json["Return", "Following"].array
            userId = json["Return", "Id"].int
            isFollowing = json["Return", "User_follows"].bool!
            let feedJsons = json["Return", "Gifs"].array
            constructFeedArrayFromJSON(feedJsons!)
            if userId == AppDelegate.getAppDelegate().getUserId() {
                titleNav.text = "Me"
                rightButtonNav.setImage(UIImage(named: "MoreIcon"), forState: .Normal)
            } else {
                titleNav.text = username
            }
            titleNav.hidden = false
            rightButtonNav.hidden = false
            feedView.reloadData()
            loadedData = true
        } else {
            AppDelegate.getAppDelegate().showError("Error", message: json["Error"].stringValue)
        }
        self.refreshControl?.endRefreshing()
    }
    
    override func navBarRightButtonAction() {
        if isSelf() {
            showAccountAlertController()
        } else if isFollowing {
            print("is following and we'll change DAT")
            unfollowUser()
        } else {
            print("is NOT following and we'll change DAT")
            followUser()
        }
        // else toggle some follow behavior
//        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
//        contactViewController.configureUserList(AddContactsViewController.CONFIG_CONTACTS) {
//            self.dismissViewControllerAnimated(true){}
//        }
//        self.presentViewController(contactViewController, animated: true, completion: nil)
    }
    
    private func isSelf() -> Bool {
        print("User's id: \(self.myUserId!)")
        print("My id: \(AppDelegate.getAppDelegate().getUserId())")
        print("User's name: \(self.username)")
        print("My username: \(AppDelegate.getAppDelegate().getUsername())")
        
        return (self.userId == AppDelegate.getAppDelegate().getUserId()
            || self.username == AppDelegate.getAppDelegate().getUsername())
    }
    
    private func followUser() {
        print("trying to follow user: \(username)")
        let appDelegate = AppDelegate.getAppDelegate()
        if let session = appDelegate.getSession() {
            let parameters = [
                "method": "FollowUserByUsername",
                "session": session,
                "username": "\(username!)"
            ]
            Alamofire.request(.POST, API.ENDPOINT_USER,
                parameters: parameters)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processFollowResponse)
            }
        } else {
            appDelegate.showError("Follow Error", message: "Could not record follow")
        }
    }
    
    private func unfollowUser() {
        print("trying to unfollow user: \(username)")
        let appDelegate = AppDelegate.getAppDelegate()
        if let session = AppDelegate.getAppDelegate().getSession() {
            let parameters = [
                "method": "UnfollowUserByUsername",
                "session": session,
                "username": "\(username!)"
            ]
            Alamofire.request(.POST, API.ENDPOINT_USER,
                parameters: parameters)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processUnfollowResponse)
            }
        } else {
            appDelegate.showError("Unfollow Error", message: "Could not record follow")
        }
    }
    
    private func processFollowResponse(value: AnyObject) {
        let json = JSON(value)
        if json["Success"] == 1 {
            isFollowing = true
        } else {
            AppDelegate.getAppDelegate().showError("Error", message: json["Error"].stringValue)
        }
        self.refreshControl.endRefreshing()
    }
    
    private func processUnfollowResponse(value: AnyObject) {
        let json = JSON(value)
        if json["Success"] == 1 {
            isFollowing = false
        } else {
            AppDelegate.getAppDelegate().showError("Error", message: json["Error"].stringValue)
        }
        self.refreshControl.endRefreshing()
    }
    
    private func showAccountAlertController() {
        let alertController = UIAlertController(title: "Keyframe", message: "My Account", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let followersAction = UIAlertAction(title: "Followers", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in
            self.presentFollowers()
        })
        alertController.addAction(followersAction)
        
        let followingAction = UIAlertAction(title: "Following", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in
            self.presentFollowing()
        })
        alertController.addAction(followingAction)
        
        let logoutAction = UIAlertAction(title: "Logout", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
            self.presentLogout()
        })
        alertController.addAction(logoutAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(alert :UIAlertAction!) in
            print("cancel button tapped")
        })
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func presentFollowers() {
        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
        contactViewController.configureUserList(AddContactsViewController.CONFIG_FOLLOWERS) {
            self.dismissViewControllerAnimated(true){}
        }
        self.presentViewController(contactViewController, animated: true, completion: nil)
    }
    
    private func presentFollowing() {
        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
        contactViewController.configureUserList(AddContactsViewController.CONFIG_FOLLOWING) {
            self.dismissViewControllerAnimated(true){}
        }
        self.presentViewController(contactViewController, animated: true, completion: nil)
    }
    
    private func presentLogout() {
        let logoutAlert = UIAlertController(title: "Logout?", message: "You will have to sign back in to access your loops", preferredStyle: UIAlertControllerStyle.Alert)
        logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        logoutAlert.addAction(UIAlertAction(title: "Logout", style: .Destructive, handler: {(alert :UIAlertAction!) in
            let appDelegate = AppDelegate.getAppDelegate()
            if appDelegate.logout() {
                appDelegate.launchLoginSignup()
            } else {
                appDelegate.showError("Logout Error", message: "Could not log you out. This is awkward.")
            }
        }))
        self.presentViewController(logoutAlert, animated: true, completion: nil)
    }
    
    override func navBarLeftButtonAction() {
        self.backButtonMethod?()
    }
}

// tableview methods
extension ProfileViewController {
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        if indexPath.section != 0 {
//            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
//        }
//    }
    // avoid an infinitely recursive view stack
    override func usernameTapped(cell: FeedCell) { }
    
    override func refresh(sender: AnyObject) {
        // Code to refresh table view
        if userId != nil {
            loadProfileByUserId(userId!)
        } else if username != nil {
            loadProfileByUsername(username!)
        }
    }

    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        if indexPath.section == 0 {
//            let userCell = feedView.dequeueReusableCellWithIdentifier("myLoopsUserCell") as! MyLoopsUserCell
//            if username == nil || isFollowing == nil {
//                return userCell
//            }
//            print("\(userId)")
//            if userId == AppDelegate.getAppDelegate().getUserId() {
//                print("loading self")
//                userCell.loadSelf(username!)
//            } else {
//                print("loading other")
//                userCell.loadOther(username!, isFollowing: isFollowing!, profPicUuid: "")
//            }
//            return userCell
//        }
//        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
//    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        if indexPath.section == 0 {
//            return view.frame.width * 1.25
//        }
//        return UITableViewAutomaticDimension
//    }
//
//    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        print("1.25w = \(view.frame.width * 1.25)")
//        if indexPath.section == 0 {
//            return view.frame.width * 1.25
//        }
//        return UITableViewAutomaticDimension
//    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if section == 0 {
//            return 1
//        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
}

