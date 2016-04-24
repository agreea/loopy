//
//  MyLoopsUserCell.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/13/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class MyLoopsUserCell: UITableViewCell {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    var _isFollowing: Bool?
    var isFollowing: Bool? {
        get {
            return _isFollowing
        }
        set(newValue) {
            _isFollowing = newValue
            updateFollowButton()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadSelf(username: String) {
        usernameLabel.text = username
        usernameLabel.hidden = false
        changeButton.hidden = false
        followButton.hidden = true
        // [CHANGE] the follow button
        // show the labels
        // show the change button
    }
    @IBAction func didPressChangeButton(sender: AnyObject) {
        // TODO: add change profile pic logic
        AppDelegate.getAppDelegate().showError("Coming Soon!", message: "You'll be able to change your profile pic soon!!")
    }
    
    func loadOther(username: String, isFollowing: Bool, profPicUuid: String) {
        // hide the change button
        usernameLabel.text = username
        changeButton.hidden = true
        followButton.hidden = false
        self.isFollowing = isFollowing
        // setProfilePic
        // show the follow button
    }
    
    @IBAction func didPressFollowButton(sender: AnyObject) {
        if isFollowing! {
            // userCellDelegate.unfollow()
        } else {
            // userCellDelegate.follow()
        }
    }
    
    private func updateFollowButton() {
        if isFollowing! {
            // set to following
        } else {
            // set to follow
        }
    }
}
