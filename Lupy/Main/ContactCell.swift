//
//  ContactViewCellTableViewCell.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/8/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
protocol ContactCellDelegate {
    func followUser(followKey: String, cell: ContactCell)
    func unfollowUser(followKey: String, cell: ContactCell)
    
}

class ContactCell: UITableViewCell {
    var _name: String?
    
    var name: String {
        get {
            return _name!
        }
        set(newValue) {
            _name = newValue
            nameLabel.text = newValue
        }
    }
    
    var followKey: String? // could be phone number or username
    
    var _following: Bool?
    var following: Bool {
        get {
            return _following!
        }
        set(newValue) {
            _following = newValue
            updateFollowButton()
        }
    }
    
    var delegate: ContactCellDelegate?
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func loadContact(phone: String, name: String, following: Bool){
        self.followKey = phone
        self.name = name
        self.following = following
        // if !registered --> set the UI to hidden? 
        // TODO: handle interaction with
    }
    
    func loadUsername(username: String, following: Bool) {
        self.followKey = username
        self.name = username
        self.following = following
    }
    
    @IBAction func didPressFollowButton(sender: AnyObject) {
        if following {
            delegate!.unfollowUser(followKey!, cell: self)
        } else {
            delegate!.followUser(followKey!, cell: self)
        }
    }
    
    private func updateFollowButton() {
        let img_name = following ? "FollowingUser" : "FollowUser"
        followButton.setImage(UIImage(named: img_name), forState: .Normal)
    }
    
}
