//
//  FeedCell.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/6/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Kingfisher
import UIImageViewAlignedSwift

class FeedCell: UITableViewCell {

    @IBOutlet weak var gifPreview: UIImageViewAligned!
    @IBOutlet weak var usernameLabel: UILabel!
//    @IBOutlet weak var timestampLabel: UILabel!
    let inFormatter = NSDateFormatter()
    let outFormatter = NSDateFormatter()
    let minute = 60
    let hour = 60 * 60
    let day = 60 * 60 * 24
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func loadItem(feedItem: FeedItem) {
        setGifPreview(feedItem.Uuid!)
        usernameLabel.text = feedItem.Username
//        setTimeLabel(feedItem.Timestamp!)
        gifPreview.alignment = UIImageViewAlignmentMask.Left
    }
    
    private func setGifPreview(gifUuid: String) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + gifUuid + "/loopy.gif")!
        let resource = Resource(downloadURL: URL, cacheKey: gifUuid + ".gif")
        
        gifPreview.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                print("Downloaded and set!")
            })
    }
    
//    private func setTimeLabel(timestamp: String) {
//        inFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
//        inFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
//        let nsTime = inFormatter.dateFromString(timestamp)
//        let timeSinceNow = NSDate().timeIntervalSinceDate(nsTime!)
//        let duration = Int(timeSinceNow)
//        if duration < day * 2 {
//            outFormatter.dateFormat = "EEE hh:mm a"
//        } else if duration < day * 7 {
//            outFormatter.dateFormat = "EEE"
//        } else {
//            outFormatter.dateFormat = "EEE MMM d"
//        }
//        let dateString = outFormatter.stringFromDate(nsTime!)
//        timestampLabel.text = dateString
//    }
}
