//
//  FeedCellMyPost.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/12/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import UIImageViewAlignedSwift
import Kingfisher
import Alamofire
import AVFoundation

class FeedCellMyPost: UITableViewCell {

    @IBOutlet weak var gifPreview: UIImageViewAligned!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var gifPreviewMarginLeft: NSLayoutConstraint!
    
    var feedViewController: FeedViewController?
    var hasGif = false
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initPlayer()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    // note when implementing the feedViewController you must assign the feedController before calling this method or setImagePreview will throw a nil pointer exception
    func loadItem(feedItem: FeedItem, userId: Int) {
        hasGif = false
        setImagePreview(feedItem.Uuid!)
        usernameLabel.text = feedItem.Username
    }
    
    func setImagePreview(uuid: String) {
        setJpeg(uuid)
    }
    
    func setJpeg(uuid: String) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + uuid + "/0.jpg")!
        let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(0.5),
            .Transition(ImageTransition.Fade(0.5))
        ]
        
        gifPreview.kf_setImageWithURL(URL,
                                      placeholderImage: nil,
                                      optionsInfo: optionInfo,
                                      completionHandler: { (image, error, cacheType, imageURL) -> () in
                                        self.reframeImage()
                                        if self.feedViewController!.canCellDownloadGif(self) {
                                            self.setGif(uuid, placeholder: image)
                                        }
        })
    }
    
    func setGif(uuid: String, placeholder: Image?) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + uuid + "/loopy.gif")!
        let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(0.5),
            .Transition(ImageTransition.Fade(0.5))
        ]
        gifPreview.kf_setImageWithURL(URL,
                                      placeholderImage: placeholder,
                                      optionsInfo: optionInfo,
                                      completionHandler: { (image, error, cacheType, imageURL) -> () in
                                        self.hasGif = true
        })
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        reframeImage()
//    }
    // Could be problem
    // reframe image, aliging right
    private func reframeImage() {
        let currentFrame = self.gifPreview.frame
        if let picSize = self.gifPreview.image?.size {
            let downscaleRatio =  currentFrame.height / picSize.height
            let downScaleWidth = picSize.width * downscaleRatio
            let farRight = currentFrame.origin.x + currentFrame.width
            let newOriginX = farRight - downScaleWidth
            gifPreview.alignment = .Right
            gifPreview.layer.cornerRadius = 6.0
            gifPreview.clipsToBounds = true
            if gifPreviewMarginLeft.constant < newOriginX - 8.0 {
                gifPreviewMarginLeft.constant = newOriginX - 8.0
                gifPreview.setNeedsLayout()
            } else {
             
            }
        } else {
            print("There was no image in gifPreview")
        }
    }
}

// AVPlayer methods
extension FeedCellMyPost {
    // fine
    func loadVideoPreview(gifUuid: String) {
        // check if the video file is in the temporary directory
        let moviePath = getTempURLForUuid(gifUuid)
        let manager = NSFileManager.defaultManager()
        if (manager.fileExistsAtPath(moviePath.path!)){
            let playerItem = AVPlayerItem(URL: moviePath)
            self.player!.replaceCurrentItemWithPlayerItem(playerItem)
            self.player!.play()
        } else {
            fetchVideoFromServer(gifUuid)
        }
        playerLayer?.hidden = false
    }
    // fine
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
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = gifPreview.frame
        gifPreview.layer.addSublayer(playerLayer!)
    }
    
    func restartVideoFromBeginning()  {
        let startTime = CMTimeMake(0, 1)
        player!.seekToTime(startTime)
        player!.play()
    }
    
    func hideVideo() {
        playerLayer?.hidden = true
    }

}

extension UIImageViewAligned {
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.frame = self.bounds
            }
        }
    }
}
