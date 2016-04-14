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

class MyLoopsViewController: FeedViewController {
    var username: String?
    var followers: [JSON]?
    var following: [JSON]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userNib = UINib(nibName: "MyLoopsUserCell", bundle: nil)
        feedView.registerNib(userNib, forCellReuseIdentifier: "myLoopsUserCell")
        feedView.rowHeight = UITableViewAutomaticDimension
        feedView.estimatedRowHeight = 426.0
        rightButtonNav.setImage(UIImage(named: "AddUser"), forState: .Normal)
        leftButtonNav.setImage(UIImage(named: "NavbarBack"), forState: .Normal)
        titleNav.text = "Me"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        attemptLoadFeed()
        print("Scrolling: \(self.scrolling)")
        print("Visible cell count: \(feedView.visibleCells.count)")
    }
    
    // loads username, followers (Array), and following (array)
    override func loadFeed(session: String) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let parameters = [
                "method": "GetMyLoopsData",
                "session": session
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
                parameters: parameters)
                .responseJSON { response in
                    self.processGetUserDataResponse(response)
                    
            }
        }
    }
    
    private func processGetUserDataResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showError("Connection Error", message: "Failed to fetch your Loopi")
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"] == 1 {
                username = json["Return","Username"].string
                followers = json["Return", "Followers"].array
                following = json["Return", "Following"].array
                let feedJsons = json["Return", "Gifs"].array
                constructFeedArrayFromJSON(feedJsons!)
            } else {
                AppDelegate.getAppDelegate().showError("Connection Error", message: json["Error"].stringValue)
            }
        }
        self.refreshControl.endRefreshing()
    }

    
    override func navBarRightButtonAction() {
        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
        presentViewController(contactViewController, animated: true, completion: nil)
    }
    
    override func navBarLeftButtonAction() {
        if let masterController = self.parentViewController as? MasterViewController? {
            masterController?.goToFeed(.Reverse)
        }
    }
}

extension MyLoopsViewController {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 0 {
            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let userCell = feedView.dequeueReusableCellWithIdentifier("myLoopsUserCell") as! MyLoopsUserCell
            if username != nil && followers != nil && following != nil {
                let followerCount = followers != nil ? followers!.count : 0
                let followingCount = following != nil ? following!.count : 0
                userCell.loadData(username!, followers: followerCount, following: followingCount)
            }
            return userCell
        }
        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 129.0
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 129.0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    func tableView( tableView : UITableView,  titleForHeaderInSection section: Int)->String? {
        if section == 1 {
            return "My Loops"
        }
        return nil
    }

}

