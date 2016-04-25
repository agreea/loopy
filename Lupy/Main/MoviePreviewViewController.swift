//
//  MoviePreviewView.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/3/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Alamofire
import SwiftyJSON
import CoreData

class MoviePreviewViewController: UIViewController {
    var moviePlayer: AVPlayerViewController!
    var player: AVPlayer?
    var images: [UIImage]?
    var coreImageView: CoreImageView?
    var uploadedBytesRepresented: Int64?
    var movieURL: NSURL?
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var moviePreview: UIView!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var progressBarCenterX: NSLayoutConstraint!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    
    var progressCompleteCenterX: NSLayoutConstraint?
    var captureModeDelegate: CaptureModeDelegate?
    var videoSource: VideoSampleBufferSource?
    
    var angleForCurrentTime: Float {
        return Float(NSDate.timeIntervalSinceReferenceDate() % M_PI*2)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let frame = bottomView.frame
        let previewWindowHeight = self.view.bounds.width * 1.25
        let bottomViewHeight = self.view.bounds.height - previewWindowHeight
        bottomView.frame = CGRect(x: 0,
                                  y: previewWindowHeight,
                                  width: frame.width,
                                  height: bottomViewHeight)
        bottomView.setNeedsLayout()
        resetUploadInterface()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        progressCompleteCenterX = progressBarCenterX
        progressBar.alpha = 0.0
        loadingLabel.alpha = 0.0
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func previewModeDidStart() {
        if coreImageView == nil {
            coreImageView = CoreImageView(frame: moviePreview.bounds)
            moviePreview.addSubview(coreImageView!)
//            self.coreImageView!.transform = CGAffineTransformMakeRotation(CGFloat(M_PI/2))
        }
        resetUploadInterface()
        videoSource = VideoSampleBufferSource(url: movieURL!) { [unowned self] buffer in
            var image = CIImage(CVPixelBuffer: buffer)
            // get transformation for this rotation
            let rotateTransform = image.imageTransformForOrientation(Int32(6))
            image = image.imageByApplyingTransform(rotateTransform)
            let background = kaleidoscope()(image)
            let mask = radialGradient(image.extent.center, radius: CGFloat(self.angleForCurrentTime) * 100)
            let output = blendWithMask(image, mask: mask)(background)
            print("output: \(output)")
            self.coreImageView!.image = output
        }
//        initPlayer()
    }
        
    func resetUploadInterface() {
        if progressBarCenterX.constant == 0 {
            progressBarCenterX.constant = progressCompleteCenterX!.constant - view.bounds.width
        }
        progressBar.alpha = 0.0
        loadingLabel.alpha = 0.0
        nextButton.hidden = false
        nextButton.alpha = 1.0
    }
    
    func initPlayer() {
        if player == nil {
            player = AVPlayer(URL: movieURL!)
        } else {
            let playerItem = AVPlayerItem(URL: movieURL!)
            player?.replaceCurrentItemWithPlayerItem(playerItem)
        }
        player!.actionAtItemEnd = .None
        //set a listener for when the video ends
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                         selector: #selector(MoviePreviewViewController.restartVideoFromBeginning),
                         name: AVPlayerItemDidPlayToEndTimeNotification,
                         object: player!.currentItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        let moviePreviewView = UIView(frame: self.view.bounds)
        moviePreviewView.layer.addSublayer(playerLayer)
        self.view.insertSubview(moviePreviewView, atIndex: 0)
        print("sublayer added")
        player!.play()
    }
    
    func restartVideoFromBeginning()  {
        let startTime = CMTimeMake(0, 1)
        player!.seekToTime(startTime)
        player!.play()
    }

    
    @IBAction func didPressCancel(sender: AnyObject) {
        // go back to the captureView
        self.captureModeDelegate!.captureModeDidStart()
    }
    
    @IBAction func didPressSend(sender: AnyObject) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            postLoop(session)
        } else {
            AppDelegate.getAppDelegate().showError("Upload Error", message: "It seems you're not logged in")
        }
    }
    
    private func postLoop(session: String) {
        uploadedBytesRepresented = 0
        progressBar.alpha = 1.0
        showLoadingLabel()
        let headers = [
            "Session": session,
            "Format": "MOV"
        ]
//        Alamofire.upload(.POST, "https://qa.yaychakula.com/api/gif/upload/", headers: headers, file: movieURL!)
//            .progress { _, totalBytesRead, totalBytesExpectedToRead in
//                self.updateUploadProgress(totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
//            }
//            .responseJSON { response in
//                self.processUploadResponse(response)
//        }
    }
    
    private func updateUploadProgress(totalBytesRead: Int64, totalBytesExpectedToRead: Int64) {
        let unrepresentedBytes = totalBytesRead - self.uploadedBytesRepresented!
        let unrepresentedPercent = Float(unrepresentedBytes) / Float(totalBytesExpectedToRead)
        if unrepresentedPercent > 0.2 {
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.moveProgressBar(unrepresentedBytes,
                                     totalBytesExpectedToRead: totalBytesExpectedToRead,
                                     unrepresentedPercent: unrepresentedPercent)
            }
            self.uploadedBytesRepresented = totalBytesRead
        }
    }
    
    private func processUploadResponse(response: (Response<AnyObject, NSError>)) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showError("Conneciton Error", message: "Failed to upload post")
            resetUploadInterface()
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"].int == 1 {
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.showUploadSuccess()
                }
                return
            } else {
                AppDelegate.getAppDelegate().showError("Upload Error", message: json["Error"].stringValue)
            }
        } else {
            AppDelegate.getAppDelegate().showError("Upload Error", message: "Failed to successfully upload")
        }
        resetUploadInterface()
    }
    
    private func showLoadingLabel(){
        self.loadingLabel.text = "Posting..."
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.loadingLabel.alpha = 1.0
            self.nextButton.alpha = 0.0
            self.view.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.nextButton.hidden = true
                }
        })
    }

    private func moveProgressBar(unrepresented: Int64, totalBytesExpectedToRead: Int64, unrepresentedPercent: Float) {
        let moveByPercent = Float(unrepresented) / Float(totalBytesExpectedToRead)
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.progressBarCenterX.constant += CGFloat(moveByPercent) * self.view.bounds.width
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // make the label transluscent to make the text transition less harsh, and then show the updated "It's up!" text
    private func showUploadSuccess() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.loadingLabel.alpha = 0.2
            self.progressBarCenterX.constant = 0.0
            self.view.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.showUploadSuccessLabel()
                }
        })
    }
    
    private func showUploadSuccessLabel() {
        self.loadingLabel.text = "It's up!"
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.loadingLabel.alpha = 1.0
            self.progressBar.alpha = 0.0
            self.view.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.startUploadSuccessLabelFadeout()
                }
        })
    }
    
    // resets the loading interface
    private func startUploadSuccessLabelFadeout() {
        UIView.animateWithDuration(0.2, delay: 1.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.loadingLabel.alpha = 0.0
            self.progressBarCenterX.constant = -self.view.bounds.width
            self.view.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.captureModeDelegate!.didFinishUpload()
                }
        })
    }
}


typealias Filter = CIImage -> CIImage

func blur(radius: Double) -> Filter {
    return { image in
        let parameters = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIGaussianBlur",
                              withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func colorGenerator(color: UIColor) -> Filter {
    return { _ in
        let parameters = [kCIInputColorKey: color]
        let filter = CIFilter(name: "CIConstantColorGenerator",
                              withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func hueAdjust(angleInRadians: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputAngleKey: angleInRadians,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIHueAdjust",
                              withInputParameters: parameters)
        return filter!.outputImage!
        
    }
}

func pixellate(scale: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            kCIInputScaleKey:scale
        ]
        return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
    }
}

func kaleidoscope() -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            ]
        return CIFilter(name: "CITriangleKaleidoscope", withInputParameters: parameters)!.outputImage!.imageByCroppingToRect(image.extent)
    }
}


func vibrance(amount: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey: image,
            "inputAmount": amount
        ]
        return CIFilter(name: "CIVibrance", withInputParameters: parameters)!.outputImage!
    }
}

func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        let filter = CIFilter(name: "CISourceOverCompositing",
                              withInputParameters: parameters)
        let cropRect = image.extent
        return filter!.outputImage!.imageByCroppingToRect(cropRect)
    }
}


func radialGradient(center: CGPoint, radius: CGFloat) -> CIImage {
    let params: [String: AnyObject] = [
        "inputColor0": CIColor(red: 1, green: 1, blue: 1),
        "inputColor1": CIColor(red: 0, green: 0, blue: 0),
        "inputCenter": CIVector(CGPoint: center),
        "inputRadius0": radius,
        "inputRadius1": radius + 1
    ]
    return CIFilter(name: "CIRadialGradient", withInputParameters: params)!.outputImage!
}

func blendWithMask(background: CIImage, mask: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: mask,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIBlendWithMask",
                              withInputParameters: parameters)
        let cropRect = image.extent
        return filter!.outputImage!.imageByCroppingToRect(cropRect)
    }
}

func colorOverlay(color: UIColor) -> Filter {
    return { image in
        let overlay = colorGenerator(color)(image)
        return compositeSourceOver(overlay)(image)
    }
}


infix operator >>> { associativity left }

func >>> (filter1: Filter, filter2: Filter) -> Filter {
    return { img in filter2(filter1(img)) }
}
