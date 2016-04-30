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

protocol FeedCellDelegate {
    func likePost( cell: FeedCell)
    func unlikePost(cell: FeedCell)
    func usernameTapped(cell: FeedCell)
    func savePostToCameraRoll(cell: FeedCell)
    func didPressMore(cell: FeedCell)
    func isSelfPost(cell: FeedCell) -> Bool
    func getTempURLForUuid(uuid: String, lofi: Bool) -> NSURL
}

class FeedCell: UITableViewCell {
    var moviePlayer: AVPlayerViewController!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var id: Int?
    var _liked: Bool?
    var delegate: FeedCellDelegate?
    var fullHeartWidth: CGFloat?
    enum PlayState {
        case Play, Pause
    }
    private var _shouldPlayState = PlayState.Play
    private var shouldPlayState: PlayState {
        get {
            return _shouldPlayState
        }
        set(newValue) {
            _shouldPlayState = newValue
            if _shouldPlayState == .Play {
                player!.play()
                // hide share interface
                hidePauseStackContainer()
            } else {
                player!.pause()
                // TODO: fade IN to showing pause stack
                showPauseStackContainer()
                // show share interface
            }
        }
    }
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
    @IBOutlet weak var pauseStackView: UIStackView!
    @IBOutlet weak var pauseStackContainerView: UIView!
    
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
        addSingleTapToPreview()
        addProfileLinkToUsername()
        gifPreview.userInteractionEnabled = true
        heartView.userInteractionEnabled = true
        pauseStackContainerView.hidden = true
        addGradientToStackViewLayer()
    }
    
    private func addGradientToStackViewLayer() {
        let gl = CAGradientLayer()
        gl.frame = pauseStackContainerView.bounds
        gl.startPoint = CGPoint(x: 0.0, y: 0.0)
        gl.endPoint = CGPoint(x: 0.0, y: 1.0)
        print("frame: \(gl.frame)")
        gl.colors = [UIColor(red: 60, green: 60, blue: 60, a: 0.0).CGColor, UIColor(netHex: 0x131313).CGColor]
        gl.locations = [0.0, 1.0]
        pauseStackContainerView.layer.insertSublayer(gl, atIndex: 0)
    }
    
    private func addSingleTapToPreview() {
        let singleTapListner = UITapGestureRecognizer()
        singleTapListner.numberOfTapsRequired = 1
        singleTapListner.addTarget(self, action:  #selector(FeedCell.didSingleTapPreview))
        gifPreview.addGestureRecognizer(singleTapListner)
    }
    
    func didSingleTapPreview() {
        // pause the video
        if shouldPlayState == .Play {
            shouldPlayState = .Pause
        } else {
            shouldPlayState = .Play
        }
        // fade in the SSD interactions
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
        delegate!.usernameTapped(self)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func loadItem(feedItem: FeedItem) {
        hasGif = false
        setImagePreview(feedItem.Uuid!)
        usernameLabel.text = feedItem.Username
        id = feedItem.Id
        self.liked = feedItem.Liked!
        shouldPlayState = .Play
    }
    
    
    @IBAction func didPressDownload(sender: AnyObject) {
        // tell the delegate the user pressed download for the cell
        // TODO: track saving state for each thing (?)
        delegate!.savePostToCameraRoll(self)
    }
    
    @IBAction func didPressMore(sender: AnyObject) {
        // tell the delegate the user pressed more for my cell
        delegate!.didPressMore(self)
    }
    
    private func showReportInterface() {
        
    }
    
    private func showDeleteInterface() {
        // show the popover action view
        
    }
    
    private func showDeleteConfirmation() {
        // show the final alert. destructive action -->
    }
    
    func setImagePreview(uuid: String) {
        let URL = NSURL(string: "https://yaychakula.com/img/" + uuid + "/0.jpg")!
        let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(0.5),
            .Transition(ImageTransition.Fade(0.5))
        ]
        gifPreview.kf_setImageWithURL(URL,
                                      placeholderImage: nil,
                                      optionsInfo: optionInfo,
                                      completionHandler: { (image, error, cacheType, imageURL) -> () in
//                                        self.reframeImage()
                                        if self.feedViewController!.canCellDownloadGif(self) {
                                            self.loadVideoPreview(uuid, lofi: false)
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
            delegate!.unlikePost(self)
        } else {
            print("Calling like")
            delegate!.likePost(self)
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
    
    private func showPauseStackContainer() {
        // set alpha 0, unhide, fade in
        self.pauseStackContainerView.alpha = 0.0
        self.pauseStackContainerView.hidden = false
        UIView.animateWithDuration(0.15, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.pauseStackContainerView.alpha = 1.0
            self.contentView.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func hidePauseStackContainer() {
        // fade out, set alpha 0, hide
        UIView.animateWithDuration(0.15, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.pauseStackContainerView.alpha = 0.0
            self.contentView.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.pauseStackContainerView.hidden = true
                }
        })
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
            print("Update frame")
        }
//        gifPreview.layer.cornerRadius = 6.0
        gifPreview.clipsToBounds = true
        gifPreview.setNeedsLayout()
    }
}

extension FeedCell {
    // fine
    func loadVideoPreview(gifUuid: String, lofi: Bool) {
        // check if the video file is in the temporary directory
        let moviePath = delegate!.getTempURLForUuid(gifUuid, lofi: lofi)
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(moviePath.path!){
            let playerItem = AVPlayerItem(URL: moviePath)
            let duration = playerItem.asset.duration
            if duration == CMTimeMake(0, 1) {
                print("fetching null video from server")
                fetchVideoFromServer(gifUuid, lofi: lofi)
            } else {
                self.player!.replaceCurrentItemWithPlayerItem(playerItem)
                self.startPlayer()
            }
        } else {
            fetchVideoFromServer(gifUuid, lofi: lofi)
        }
    }
    
    // fine
    func fetchVideoFromServer(gifUuid: String, lofi: Bool) {
        let fileEnding = lofi ? "/ds_c.MOV" : "/c_r.MOV"
        let videoUrl = "https://yaychakula.com/img/" + gifUuid + "/c_r.MOV"
        Alamofire.request(.GET, videoUrl).response { request, response, data, error in
            print("For \(gifUuid), lofi: \(lofi). Fetched bytes: \(data!.length)")
            if data!.length <= 2884 {
                self.loadVideoPreview(gifUuid, lofi: true)
                return
            }else if self.writeVideoFile(gifUuid, data: data!, lofi: lofi) {
                let movieURL = self.delegate!.getTempURLForUuid(gifUuid, lofi: lofi)
                let playerItem = AVPlayerItem(URL: movieURL)
                
                if playerItem.duration > CMTimeMake(0, 1) {
                    self.player?.replaceCurrentItemWithPlayerItem(playerItem)
                    self.startPlayer()
                } else if lofi == false {
                    self.loadVideoPreview(gifUuid, lofi: true)
                }
            } else {
                print("failed to fetch")
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
        
    private func writeVideoFile(gifUuid: String, data: NSData, lofi: Bool) -> Bool {
        let moviePath = delegate!.getTempURLForUuid(gifUuid, lofi: lofi)
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
        if !isPlayerPlaying() && shouldPlayState == .Play {
            player!.play()
        }
    }
    
    // used to describe the physical state of the player,
    // as opposed to shouldPlayState, which describes the user's "will to play"
    private func isPlayerPlaying() -> Bool {
        return player!.rate != 0 && player!.error == nil
    }
    
    func pauseVideo() {
        if isPlayerPlaying() {
            player!.pause()
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
        let viewHeight = self.bounds.height
        let viewWidth = self.bounds.width
        if let playerSize = layer.player?.currentItem?.presentationSize {
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            if playerSize.width == 0.0 && playerSize.height == 0.0 {
                layer.frame = self.bounds
                self.clipsToBounds = true
                return
            }
            if playerSize.width < viewWidth { // too narrow
                print("=====")
                print("Too narrow")
                print("View width: \(viewWidth)")
                print("player height: \(playerSize.height)")
                print("player width: \(playerSize.width)")
                let frameScalar = viewWidth / playerSize.width
                let newWidth = viewWidth
                let newHeight = playerSize.height * frameScalar
                layer.frame = CGRect.rectAroundCenter(self.bounds.center, width: newWidth, height: newHeight)
                print("New frame: \(layer.frame)")
            } else if playerSize.height < viewHeight { // too short
                print("Too short")
                print("View width: \(viewWidth)")
                print("player height: \(playerSize.height)")
                print("player width: \(playerSize.width)")
                let frameScalar = viewHeight / playerSize.height
                let newWidth = playerSize.width * frameScalar
                let newHeight = viewHeight
                layer.frame = CGRect.rectAroundCenter(self.bounds.center, width: newWidth, height: newHeight)
                print("New frame: \(layer.frame)")
            }
        }
        self.clipsToBounds = true
        layer.setNeedsDisplay()
        layer.setNeedsLayout()

    }
}
