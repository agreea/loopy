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
import AVFoundation
import AVKit
import Alamofire

class FeedCell: UITableViewCell {
    var moviePlayer: AVPlayerViewController!
    var player: AVPlayer?
    
    @IBOutlet weak var gifPreview: UIImageViewAligned!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avPlayerView: UIView!
    
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
        avPlayerView.hidden = true
//        initPlayer()
        // Initialize media player
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func loadItem(feedItem: FeedItem, userId: Int) {
        setGif(feedItem.Uuid!)
        usernameLabel.text = feedItem.Username
        self.userId = userId
        self.authorId = feedItem.User_id
//        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//        dispatch_async(dispatch_get_global_queue(priority, 0)) {
//            self.loadVideoPreview(feedItem.Uuid!)
//        }
//        setTimeLabel(feedItem.Timestamp!)
    }
    
    func setGif(gifUuid: String) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + gifUuid + "/loopy.gif")!
        let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(0.5),
            .Transition(ImageTransition.Fade(0.5))
        ]
        gifPreview.kf_setImageWithURL(URL,
                                      placeholderImage: nil,
                                      optionsInfo: optionInfo,
                                      completionHandler: { (image, error, cacheType, imageURL) -> () in
                self.roundGifCorners()
            })
    }
    
    func loadVideoPreview(gifUuid: String) {
        // check if the video file is in the temporary directory
        let moviePath = getTempURLForUuid(gifUuid)
        let manager = NSFileManager.defaultManager()
        if (manager.fileExistsAtPath(moviePath.path!)){
                print("about to instantiate item: \(NSDate().timeIntervalSince1970)")
                let playerItem = AVPlayerItem(URL: moviePath)
                print("about to replace item: \(NSDate().timeIntervalSince1970)")
                self.player!.replaceCurrentItemWithPlayerItem(playerItem)
                print("about to play: \(NSDate().timeIntervalSince1970)")
                self.player!.play()
                print("played: \(NSDate().timeIntervalSince1970)")
        } else {
            fetchVideoFromServer(gifUuid)
        }
    }
    
    
    
    
    func fetchVideoFromServer(gifUuid: String) {
        let videoUrl = "https://yaychakula.com/img/" + gifUuid + "/dst.MOV"
        Alamofire.request(.GET, videoUrl).response { request, response, data, error in
            print("Fetched bytes: \(data!.length)")
            if self.writeVideoFile(gifUuid, data: data!) {
                let movieURL = self.getTempURLForUuid(gifUuid)
                let playerItem = AVPlayerItem(URL: movieURL)
                self.player?.replaceCurrentItemWithPlayerItem(playerItem)
                self.player!.play()
            } else {
                // todo: show error
            }
        }        
    }

    func getTempURLForUuid(uuid: String) -> NSURL {
        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let movieName = uuid + "_dst.MOV"
        return tempDir.URLByAppendingPathComponent(movieName)
    }
    
    private func writeVideoFile(gifUuid: String, data: NSData) -> Bool {
        let moviePath = getTempURLForUuid(gifUuid)
        do {
            try data.writeToFile(moviePath.path!, options: .AtomicWrite)
        } catch {
//            print("\(error)")
        }
        let manager = NSFileManager.defaultManager()
        return manager.fileExistsAtPath(moviePath.path!)
    }

    private func initPlayer() {
        player = AVPlayer()
        player!.actionAtItemEnd = .None
        //set a listener for when the video ends
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                         selector: #selector(MoviePreviewViewController.restartVideoFromBeginning),
                         name: AVPlayerItemDidPlayToEndTimeNotification,
                         object: player!.currentItem)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = avPlayerView.bounds
        avPlayerView.layer.addSublayer(playerLayer)
        print("sublayer added")
    }
    
    func restartVideoFromBeginning()  {
        let startTime = CMTimeMake(0, 1)
        player!.seekToTime(startTime)
        player!.play()
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
