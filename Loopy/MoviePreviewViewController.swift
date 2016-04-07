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

class MoviePreviewViewController: UIViewController {
    var moviePlayer: AVPlayerViewController!
    var movieURL: NSURL?
    var player: AVPlayer?
    @IBOutlet weak var moviePreview: UIView!
    var captureModeDelegate: CaptureModeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func previewModeDidStart() {
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

    //function to restart the video
    func restartVideoFromBeginning()  {
        //create a CMTime for zero seconds so we can go back to the beginning
        let startTime = CMTimeMake(0, 1)
        player!.seekToTime(startTime)
        player!.play()
    }

    
    @IBAction func didPressCancel(sender: AnyObject) {
        // go back to the captureView
        self.captureModeDelegate!.captureModeDidStart()
    }

    @IBAction func didPressSend(sender: AnyObject) {
        // send the gif (?)
        let headers = [
            "Session": "c2dc4cc4-08cb-4c18-be8b-6d8ef0c812cc",
            "Format": "MOV"
        ]
        let request = Alamofire.upload(.POST, "https://qa.yaychakula.com/api/gif/upload/",
                                       headers: headers, file: movieURL!).responseJSON { response in
            print(response.request)  // original URL request
            print(response.response) // URL response
            print(response.data)     // server data
            print(response.result)   // result of response serialization
            if let JSON = response.result.value {
                print("JSON: \(JSON)")
            }
        }
        print(request)
    }
}
