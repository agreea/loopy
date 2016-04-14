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
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadData(username: String, followers: Int, following: Int) {
        usernameLabel.text = username
        followersCountLabel.text = "\(followers)"
        followingCountLabel.text = "\(following)"
    }
}
