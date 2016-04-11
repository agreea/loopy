//
//  ContactViewCellTableViewCell.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/8/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
protocol ContactCellDelegate {
    func followUser(phone: String, cell: ContactCell)
    func unfollowUser(phone: String, cell: ContactCell)
    
}
class ContactCell: UITableViewCell {
    var _name: String?
    
    var name: String {
        get {
            print("In get name")
            return _name!
        }
        set(newValue) {
            print("S E T name")
            _name = newValue
            nameLabel.text = newValue
        }
    }
    
    var phone: String?
    
    var _following: Bool?
    var following: Bool {
        get {
            print("In get following")
            return _following!
        }
        set(newValue) {
            print("S E T following")
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
        self.phone = phone
        self.name = name
        self.following = following
        // if !registered --> set the UI to hidden? 
        // TODO: handle interaction with
    }
    
    @IBAction func didPressFollowButton(sender: AnyObject) {
        if following {
            delegate!.unfollowUser(phone!, cell: self)
        } else {
            delegate!.followUser(phone!, cell: self)
        }
    }
    
    private func updateFollowButton() {
        let img_name = following ? "FollowingUser" : "FollowUser"
        followButton.setImage(UIImage(named: img_name), forState: .Normal)
    }
    
}
