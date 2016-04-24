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
import Haneke
import FLAnimatedImage

protocol FeedCellDelegate {
    func likePost(id: Int, cell: FeedCell)
    func unlikePost(id: Int, cell: FeedCell)
    func usernameTapped(username: String)
}


class FeedCell: UITableViewCell {
    var moviePlayer: AVPlayerViewController!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var id: Int?
    var _liked: Bool?
    var delegate: FeedCellDelegate?
    var fullHeartWidth: CGFloat?
//    var _username: String?
//    var username: String? {
//        get {
//            return _username
//        }
//        set(newValue){
//            usernameLabel.text = newValue
//            _username = newValue
//        }
//    }
    var liked: Bool {
        get {
            return _liked!
        }
        set(newValue) {
            _liked = newValue
            updateHeartButton()
        }
    }
    
    @IBOutlet weak var gifPreview: UIImageViewAligned!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var heartView: UIImageView!
    @IBOutlet weak var heartViewWidth: NSLayoutConstraint!
    @IBOutlet weak var profilePic: UIImageView!
    
//    @IBOutlet weak var avPlayerView: UIView!
    
//    @IBOutlet weak var timestampLabel: UILabel!
//    let inFormatter = NSDateFormatter()
//    let outFormatter = NSDateFormatter()
//    let outterPadding = CGFloat(8.0) // literal defined as per interface builder guidelines
//    let minute = 60
//    let hour = 60 * 60
//    let day = 60 * 60 * 24
    var feedViewController: FeedViewController?
    var hasGif = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initPlayer()
        addDoubleTapToPreview()
        addProfileLinkToUsername()
        gifPreview.userInteractionEnabled = true
        heartView.userInteractionEnabled = true
        profilePic.layer.cornerRadius = profilePic.frame.width / 2
        profilePic.clipsToBounds = true
    }
    
    private func addDoubleTapToPreview() {
        let doubleTapListener = UITapGestureRecognizer()
        doubleTapListener.numberOfTapsRequired = 2
        doubleTapListener.addTarget(self, action: #selector(FeedCell.didDoubleTapPreview))
        gifPreview.addGestureRecognizer(doubleTapListener)
    }
    
    private func addProfileLinkToUsername() {
        let usernameTapListener = UITapGestureRecognizer()
        usernameTapListener.numberOfTapsRequired = 1
        usernameTapListener.addTarget(self, action: #selector(FeedCell.didTapUsername))
        usernameLabel.addGestureRecognizer(usernameTapListener)
    }
    
    func didTapUsername() {
        print("Username tapped")
        delegate!.usernameTapped(usernameLabel.text!)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func loadItem(feedItem: FeedItem, userId: Int) {
        hasGif = false
        setImagePreview(feedItem.Uuid!)
        usernameLabel.text = feedItem.Username
        id = feedItem.Id
        self.liked = feedItem.Liked!
//                    self.heartView.transform = CGAffineTransformMakeScale(0,0)
//        self.heartViewWidth.constant = 0.0
//        self.layoutIfNeeded()
//        avPlayerView.hidden = true
//        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//        dispatch_async(dispatch_get_global_queue(priority, 0)) {
//            self.loadVideoPreview(feedItem.Uuid!)
//        }
//        setTimeLabel(feedItem.Timestamp!)
    }
    
    func setImagePreview(uuid: String) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + uuid + "/0c.jpg")!
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
                                            self.loadVideoPreview(uuid)
                                        }
        })
    }
    
    @IBAction func didPressHeartButton(sender: AnyObject) {
        // if liked --> set to unlike
        
        changeLikeStatus()
    }
    func didDoubleTapPreview() {
        startLikedAnimation()
        if !liked {
            changeLikeStatus()
        }
    }
    func changeLikeStatus() {
        print("Noticed double tap")
        if liked {
            print("Calling unlike")
            delegate!.unlikePost(id!, cell: self)
        } else {
            print("Calling like")
            delegate!.likePost(id!, cell: self)
        }
    }
    
    private func startLikedAnimation() {
        heartView.hidden = false
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.heartView.alpha = 1.0
            self.heartViewWidth.constant = 100.0
            self.layoutIfNeeded()
            }, completion: { finished in
                print("Fadein finished: \(finished)")
                print("Heartview width: \(self.heartViewWidth.constant)")
                self.finishLikedAnimation()
                if finished {
                }
        })
    }
    
    private func finishLikedAnimation() {
        print("Finished like animation")
        print("About to fade out: \(self.heartViewWidth)")
        UIView.animateWithDuration(0.25, delay: 0.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.heartView.alpha = 0.0
            self.layoutIfNeeded()
            }, completion: { finished in
                print("Faded out: \(self.heartViewWidth)")
                if finished {
                    self.heartView.hidden = true
                    self.heartViewWidth.constant = 0.0
                }
        })
    }
    
    func updateHeartButton() {
        let imageName = liked ? "Heart" : "HeartOutline"
        heartButton.setImage(UIImage(named: imageName), forState: .Normal)
    }
    
    func setGif(uuid: String, placeholder: Image?) {
//        let URL = NSURL(string: "https://yaychakula.com/img/" + uuid + "/loopy.gif")!
        
//        let cache = Shared.dataCache
//        cache.fetch(URL: URL).onSuccess { data in
//            let gif = FLAnimatedImage(animatedGIFData: data)
//            self.gifPreview.animatedImage = gif
//        }
        
//        let optionInfo: KingfisherOptionsInfo = [
//            .DownloadPriority(0.5),
//            .Transition(ImageTransition.Fade(0.5))
//        ]
//        gifPreview.kf_setImageWithURL(URL,
//                                      placeholderImage: placeholder,
//                                      optionsInfo: optionInfo,
//                                      completionHandler: { (image, error, cacheType, imageURL) -> () in
//                                        self.hasGif = true
//        })
    }
    
    private func reframeImage() {
        if let gifSize = self.gifPreview.image?.size {
            let currentFrame = self.gifPreview.frame
            // get the current height of the gif
            // divide that by the current height of the preview, you've got the ratio
//            let downscaleRatio =  currentFrame.height / gifSize.height
//            let downScaleWidth = gifSize.width * downscaleRatio
//            gifPreview.alignment = .Left
            self.gifPreview!.frame = CGRectMake(currentFrame.origin.x,
                                                currentFrame.origin.y,
                                                currentFrame.width,
                                                currentFrame.width * 1.25)
        }
//        gifPreview.layer.cornerRadius = 6.0
        gifPreview.clipsToBounds = true
        gifPreview.setNeedsLayout()
    }
}

extension FeedCell {
    // fine
    func loadVideoPreview(gifUuid: String) {
        // check if the video file is in the temporary directory
        let moviePath = getTempURLForUuid(gifUuid)
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(moviePath.path!){
            let playerItem = AVPlayerItem(URL: moviePath)
            let duration = playerItem.asset.duration
            if duration == CMTimeMake(0, 1) {
                print("fetching null video from server")
                fetchVideoFromServer(gifUuid)
            } else {
                self.player!.replaceCurrentItemWithPlayerItem(playerItem)
                self.startPlayer()
            }
        } else {
            fetchVideoFromServer(gifUuid)
        }
    }
    // fine
    func fetchVideoFromServer(gifUuid: String) {
        let videoUrl = "https://yaychakula.com/img/" + gifUuid + "/ds_c.MOV"
        Alamofire.request(.GET, videoUrl).response { request, response, data, error in
            print("For \(gifUuid) Fetched bytes: \(data!.length)")
            if self.writeVideoFile(gifUuid, data: data!) {
                let movieURL = self.getTempURLForUuid(gifUuid)
                let playerItem = AVPlayerItem(URL: movieURL)
                self.player?.replaceCurrentItemWithPlayerItem(playerItem)
                self.startPlayer()
            } else {
                // todo: show error
            }
        }
    }
    
    func startPlayer() {
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                         selector: #selector(FeedCell.restartVideoFromBeginning),
                         name: AVPlayerItemDidPlayToEndTimeNotification,
                         object: player?.currentItem)
        self.player!.play()
        self.playerLayer?.hidden = false
    }
    
    func getTempURLForUuid(uuid: String) -> NSURL {
        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let movieName = uuid + "_ds_c.MOV"
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
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = gifPreview.bounds
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
    
    func playVideo() {
        if !isPlayerPlaying() {
            player!.play()
        } else {
            print("didn't play")
        }
    }
    
    private func isPlayerPlaying() -> Bool {
        return player!.rate != 0 && player!.error == nil
    }
    
    func pauseVideo() {
        if isPlayerPlaying() {
            player!.pause()
        } else {
            print("didn't pause")
        }
    }
}

extension UIImageViewAligned {
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                if let playerLayer = sublayer as? AVPlayerLayer {
                    resizePlayerLayer(playerLayer)
                }
            }
        }
    }
    
    private func resizePlayerLayer(layer: AVPlayerLayer) {
        if let playerSize = layer.player?.currentItem?.presentationSize {
            if playerSize.height > frame.height {
                layer.frame = self.bounds
            }
        }
    }
}
