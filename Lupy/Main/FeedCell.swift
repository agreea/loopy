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
import GPUImage

protocol FeedCellDelegate {
    func likePost( cell: FeedCell)
    func unlikePost(cell: FeedCell)
    func usernameTapped(cell: FeedCell)
    func savePostToCameraRoll(cell: FeedCell)
    func didPressMore(cell: FeedCell)
    func isSelfPost(cell: FeedCell) -> Bool
    func loadVideo(cell: FeedCell)
    func getFirstFrameURL(cell: FeedCell) -> NSURL
}

class FeedCell: UITableViewCell {
    var moviePlayer: AVPlayerViewController!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var id: Int?
    var delegate: FeedCellDelegate?
    var fullHeartWidth: CGFloat?
    var downloading = false
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
            } else {
                player!.pause()
            }
        }
    }
    
    var _liked: Bool?
    var liked: Bool {
        get {
            return _liked!
        }
        set(newValue) {
            _liked = newValue
            heartButton.alpha = _liked! ? 1.0 : 0.0
            heartButton.enabled = _liked!
        }
    }
    var _username: String?
    var username: String? {
        get {
            return _username
        }
        set(newValue) {
            _username = newValue
            usernameLabel.text = _username
        }
    }
    var uuid: String?
    
    @IBOutlet weak var gifPreview: UIImageViewAligned!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var heartView: UIImageView!
    @IBOutlet weak var heartViewWidth: NSLayoutConstraint!
    @IBOutlet weak var pauseStackView: UIStackView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadButtonHeight: NSLayoutConstraint!
    
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
            playerLayer!.hidden = false
            print("playerlayer hidden: \(playerLayer!.hidden)")
        }
        print("single tapped to: \(shouldPlayState)")
        print("player detail: \(player!.currentItem!.duration)")
        print("playerlayer hidden: \(playerLayer!.hidden)")
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
        playerLayer?.hidden = true
        username = feedItem.Username!
        uuid = feedItem.Uuid!
        print("Cell load view called, my id is: \(id)")
        setImagePreview()
        usernameLabel.text = feedItem.Username
        id = feedItem.Id
        print("Load Video called for \(id)")
        self.liked = feedItem.Liked!
        shouldPlayState = .Play
        downloading = false
        print("Cell's height in loadItem: \(self.contentView.frame.height)")
    }
    
    
    @IBAction func didPressDownload(sender: AnyObject) {
        // tell the delegate the user pressed download for the cell
        // TODO: track saving state for each thing (?)
        delegate!.savePostToCameraRoll(self)
        downloading = true
        downloadButton.userInteractionEnabled = false
        downloadButton.setImage(UIImage(named: "Downloading"), forState: .Normal)
        rotateDownloadButton()
        // set the button to spinny
        // rotate view
    }
    
    func saveGifComplete(success: Bool) {
        downloading = false
        if success {
//            showDownloadSuccessAnimation()
            // success scale:
            // start scaling from 90 -> 120 in 0.15 seconds
            // once that's done take 0.25s as long to scale down to 1
            
            // success opacity:
            // fade out rotating download button in .1s (showDownloadSuccess)
            // once that's done set the downloading button to a success check (startDownloadSuccessFadein)
            // once that's done immediately reveal the success check, start success scale (startDownloadSuccessFadein)
            // .75s at 100% (delay in downloadSuccessFadein)
            // .375s from 100 to 0 (execution time of dlSuccessFadein)
            // set download button to download icon (dlInteractiveFadein)
            // .21s from 0 to 100 download button opacity (dlInteractiveFadein)
        } else {
            AppDelegate.getAppDelegate().showError("Gif Save Error", message: "Couldn't save the loop! :(")
        }
    }
    
    private func showDownloadSuccessAnimation() {
        // hide the rotating animation button
        self.downloadButton.enabled = false
        self.downloadButton.userInteractionEnabled = false
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.downloadButton.alpha = 0.0
            self.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.startDownloadSuccessFadein()
                }
        })
    }

    private func startDownloadSuccessFadein() {
        self.downloadButton.setImage(UIImage(named:"DownloadSuccess"), forState: .Normal)
        self.layoutIfNeeded()
        self.startDownloadSuccessUpscale()
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.downloadButton.alpha = 1.0
            self.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.startDownloadSuccessFadeout()
                }
        })
    }
    
    private func startDownloadSuccessFadeout() {
        UIView.animateWithDuration(0.375, delay: 0.75, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.downloadButton.alpha = 0.0
            self.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.startInteractiveDownloadFadein()
                }
        })
    }
    
    private func startDownloadSuccessUpscale() {
        print("upscale")
        downloadButtonHeight.constant = 45.0
        self.layoutIfNeeded()
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.downloadButtonHeight.constant = 80.0
            self.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.startDownloadSuccessDownscale()
                }
        })
    }
    
    private func startDownloadSuccessDownscale() {
        print("downscale")
        UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.downloadButtonHeight.constant = 50.0
            self.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func startInteractiveDownloadFadein() {
        print("interactive comin back")
        self.downloadButton.enabled = true
        self.downloadButton.userInteractionEnabled = true
        self.downloadButton.setImage(UIImage(named: "Download"), forState: .Normal)
        UIView.animateWithDuration(0.21, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.downloadButton.alpha = 1.0
            self.layoutIfNeeded()
            }, completion: nil)
    }

    private func rotateDownloadButton() {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2.0)
        rotateAnimation.duration = 1.0
        rotateAnimation.delegate = self
        downloadButton.layer.addAnimation(rotateAnimation, forKey: nil)
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if downloading {
            rotateDownloadButton()
        } else {
            showDownloadSuccessAnimation()
        }
    }


    @IBAction func didPressMore(sender: AnyObject) {
        // tell the delegate the user pressed more for my cell
        delegate!.didPressMore(self)
    }
        
    func setImagePreview() {
        print("Top of set image preview")
        print("Player layer is hidden?: \(self.playerLayer!.hidden)")
        let URL = NSURL(string: "https://s3.amazonaws.com/keyframecontent/" + username! + "_" + uuid! + "/f.jpg")!
        let optionInfo: KingfisherOptionsInfo = [
            .DownloadPriority(0.5),
            .Transition(ImageTransition.Fade(0.5))
        ]
        gifPreview.kf_setImageWithURL(URL,
                                      placeholderImage: nil,
                                      optionsInfo: optionInfo,
                                      completionHandler: { (image, error, cacheType, imageURL) -> () in
                                        if self.feedViewController!.canCellDownloadGif(self) {
                                            print("image completion: about to load video")
                                            self.playerLayer!.hidden = true
                                            self.delegate!.loadVideo(self)
                                        } else {
                                            print("can't load video??")
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

    private func reframeImage() {
        if self.gifPreview.image?.size != nil {
            let currentFrame = self.gifPreview.frame
            self.gifPreview!.frame = CGRectMake(currentFrame.origin.x,
                                                currentFrame.origin.y,
                                                currentFrame.width,
                                                currentFrame.width * 1.25)
        }
        gifPreview.clipsToBounds = true
        gifPreview.setNeedsLayout()
    }
    
    func fadeToNonScrollState() {
        if self.alpha > 0.5 {
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.alpha = 1.0
                self.contentView.layoutIfNeeded()
                }, completion: nil)
        } else {
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.alpha = 0.0
                self.contentView.layoutIfNeeded()
                }, completion: nil)

        }
    }
}

extension FeedCell {    
//    func videoLoaded(url: NSURL) {
////        let gpuImageMovie = GPUImageMovie()
//        // check that the movie is different from the current one (same --> return)
//        // create a new GPUImageMovie
//        // create a new GPUImageView
//        // set the GPUImageMovie at index 100 in gifPreview
//        // show it in the subview
//    }
    
    func prepareForDisappear() {
        // stop processing GPUMovie
        // remove GPUImageView from super view
        // set GPUImageView to nil
    }

    func videoLoaded(url: NSURL) {
        if let playerURLAsset = player?.currentItem?.asset as? AVURLAsset {
            if playerURLAsset.URL == url {
                player!.play()
                playerLayer!.frame = gifPreview.bounds
                self.playerLayer!.hidden = false
                print("Avoided unnecessary reload, should be playing")
                return
            }
        }
        let playerItem = AVPlayerItem(URL: url)
        if playerItem.duration == CMTimeMake(0, 1) {
            print("Duration was 0, exit")
            return
        }
        player!.replaceCurrentItemWithPlayerItem(playerItem)
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                         selector: #selector(FeedCell.restartVideoFromBeginning),
                         name: AVPlayerItemDidPlayToEndTimeNotification,
                         object: player?.currentItem)
        self.player!.play()
        playerLayer?.frame = gifPreview.bounds
        self.playerLayer!.hidden = false
    }
    
    private func initPlayer() {
        player = AVPlayer()
        player!.actionAtItemEnd = .None
        //set a listener for when the video ends
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = gifPreview.bounds
        playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
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
        print("Play video called on \(id)")
        
        if !isPlayerPlaying() && shouldPlayState == .Play {
            print("Play video EXECUTED")
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
