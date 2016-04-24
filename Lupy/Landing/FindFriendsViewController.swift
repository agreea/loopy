//
//  FindFriendsViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/8/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Contacts

class FindFriendsViewController: UIViewController {
    let contactStore = CNContactStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func didPressSearchContacts(sender: AnyObject) {
        // launch contacts screen
        AppDelegate.getAppDelegate().launchAddContacts(true)
    }
    
    @IBAction func didPressLater(sender: AnyObject) {
        // launch main feed
        AppDelegate.getAppDelegate().launchMainExperience()
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
