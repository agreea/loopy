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
    var userId: Int?
    var authorId: Int?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func loadItem(feedItem: FeedItem, userId: Int) {
        setGifPreview(feedItem.Uuid!)
        usernameLabel.text = feedItem.Username
        self.userId = userId
        self.authorId = feedItem.User_id
//        setTimeLabel(feedItem.Timestamp!)
    }
    
    private func setGifPreview(gifUuid: String) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + gifUuid + "/loopy.gif")!        
        gifPreview.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                self.roundGifCorners()
            })
    }
    private func roundGifCorners() {
        if let gifSize = self.gifPreview.image?.size {
            let currentFrame = self.gifPreview.frame
            // get the current height of the gif
            // divide that by the current height of the preview, you've got the ratio
            let downscaleRatio =  currentFrame.height / gifSize.height
            self.gifPreview!.frame = CGRectMake(currentFrame.origin.x,
                                                currentFrame.origin.y,
                                                gifSize.width * downscaleRatio,
                                                currentFrame.height);
        }
        self.gifPreview.layer.cornerRadius = 6.0
        self.gifPreview.clipsToBounds = true
        self.gifPreview.alignment = (authorId == userId) ? .Right : .Left
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
