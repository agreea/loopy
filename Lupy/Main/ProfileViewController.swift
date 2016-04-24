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
    var userId: Int?
    var followers: [JSON]?
    var following: [JSON]?
    var posts: [JSON]?
    var likes: [JSON]?
    var isFollowing: Bool?
    var backButtonMethod: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        let userNib = UINib(nibName: "MyLoopsUserCell", bundle: nil)
        feedView.registerNib(userNib, forCellReuseIdentifier: "myLoopsUserCell")
//        rightButtonNav.setImage(UIImage(named: "AddUser"), forState: .Normal)
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if userId != nil {
            loadProfileByUserId(userId!)
        } else if username != nil {
            loadProfileByUsername(username!)
        }
        leftButtonNav.hidden = backButtonMethod == nil
//        attemptLoadFeed()
        print("Scrolling: \(self.scrolling)")
        print("Visible cell count: \(feedView.visibleCells.count)")
    }
    
    // loads username, followers (Array), and following (array)
    func loadProfileByUserId(userId: Int) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let parameters = [
                "method": "GetProfileByUserId",
                "session": session,
                "userId": "\(userId)"
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                parameters: parameters)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processGetUserDataResponse)
            }
        }
    }
    
    func loadProfileByUsername(username: String) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let parameters = [
                "method": "GetProfileByUsername",
                "session": session,
                "username": "\(username)"
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
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
            // if these aren't *nil* --> set "change" button to visible
            // set follow button to invisible
            // set followers/following labels to visibile
            followers = json["Return", "Followers"].array
            following = json["Return", "Following"].array
            userId = json["Return", "Id"].int
            isFollowing = json["Return", "User_follows"].bool!
            let feedJsons = json["Return", "Gifs"].array
            constructFeedArrayFromJSON(feedJsons!)
            if userId == AppDelegate.getAppDelegate().getUserId() {
                titleNav.text = "Me"
            } else {
                titleNav.text = username
            }
            feedView.reloadData()
        } else {
            AppDelegate.getAppDelegate().showError("Error", message: json["Error"].stringValue)
        }
        self.refreshControl.endRefreshing()
    }
    
    override func navBarRightButtonAction() {
        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
        presentViewController(contactViewController, animated: true, completion: nil)
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
    override func usernameTapped(username: String) { }
    
    override func refresh(sender: AnyObject) {
        // Code to refresh table view
        if userId != nil {
            loadProfileByUserId(userId!)
        } else if username != nil {
            loadProfileByUsername(username!)
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let userCell = feedView.dequeueReusableCellWithIdentifier("myLoopsUserCell") as! MyLoopsUserCell
            if username == nil || isFollowing == nil {
                return userCell
            }
            print("\(userId)")
            if userId == AppDelegate.getAppDelegate().getUserId() {
                print("loading self")
                userCell.loadSelf(username!)
            } else {
                print("loading other")
                userCell.loadOther(username!, isFollowing: isFollowing!, profPicUuid: "")
            }
            return userCell
        }
        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
        
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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
        if section == 0 {
            return 1
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
}

