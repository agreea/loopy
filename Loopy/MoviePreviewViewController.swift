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
    var movieURL: NSURL?
    var player: AVPlayer?
    var uploadedBytesRepresented: Int64?
    var coreDataDelegate: CoreDataDelegate?
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var moviePreview: UIView!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var progressBarCenterX: NSLayoutConstraint!
    @IBOutlet weak var loadingLabel: UILabel!
    
    var progressCompleteCenterX: NSLayoutConstraint?
    var captureModeDelegate: CaptureModeDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        if progressBarCenterX.constant == 0 {
            progressBarCenterX.constant = progressCompleteCenterX!.constant - view.bounds.width
        }
    }
    
    override func viewWillAppear(animated: Bool) {
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
        nextButton.alpha = 1.0
        nextButton.hidden = false
        initPlayer()
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
        if let session = coreDataDelegate?.getSession() {
            postLoop(session)
        } else {
            // todo: show failed to upload interaction
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
        Alamofire.upload(.POST, "https://qa.yaychakula.com/api/gif/upload/", headers: headers, file: movieURL!)
            .progress { _, totalBytesRead, totalBytesExpectedToRead in
                self.updateUploadProgress(totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
            }
            .responseJSON { response in
                self.processUploadResponse(response)
        }
    }
    
    private func updateUploadProgress(totalBytesRead: Int64, totalBytesExpectedToRead: Int64) {
        let unrepresentedBytes = totalBytesRead - self.uploadedBytesRepresented!
        let unrepresentedPercent = Float(unrepresentedBytes) / Float(totalBytesExpectedToRead)
        if unrepresentedPercent > 0.1 {
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.moveProgressBar(unrepresentedBytes,
                                     totalBytesExpectedToRead: totalBytesExpectedToRead,
                                     unrepresentedPercent: unrepresentedPercent)
            }
            self.uploadedBytesRepresented = totalBytesRead
        }
        print("\(totalBytesRead) of \(totalBytesExpectedToRead)")
    }
    
    private func processUploadResponse(response: (Response<AnyObject, NSError>)) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"].int == 1 {
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    self.showUploadSuccess()
                }
            }
        } else {
            print("Couldn't parse JSON")
        }
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
            }, completion: nil)
    }
}
