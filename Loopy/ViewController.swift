//
//  ViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 3/19/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import MobileCoreServices
import Kingfisher
import Regift
import Alamofire

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CaptureModeDelegate {
    
    @IBOutlet weak var scrollWindow: UIScrollView!
    var moviePreviewController: MoviePreviewViewController?
    var captureViewController: CaptureViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initCaptureViewController()
        self.initFeedViewController()
        self.initMoviePreviewController()
        scrollWindow.contentSize = CGSizeMake(self.view.frame.width * 2, self.view.frame.size.height)
        scrollWindow.showsHorizontalScrollIndicator = false
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    private func initMoviePreviewController(){
        self.moviePreviewController = MoviePreviewViewController(nibName: "MoviePreviewView", bundle: nil)
        print("init")
        self.moviePreviewController!.captureModeDelegate = self
        print("assigned member vars")
        self.addChildViewController(moviePreviewController!)
        moviePreviewController!.view.hidden = true
        self.captureViewController!.view.addSubview(moviePreviewController!.view)
        print("added subview")
        moviePreviewController!.didMoveToParentViewController(self)
        print("done")

    }
    
    private func initCaptureViewController(){
        self.captureViewController = CaptureViewController(nibName: "CaptureView", bundle: nil)
        self.captureViewController!.captureModeDelegate = self
        self.addChildViewController(self.captureViewController!)
        self.scrollWindow.addSubview(captureViewController!.view)
        captureViewController!.didMoveToParentViewController(self)
    }
    
    private func initFeedViewController() {
        let feedView = FeedView(nibName: "FeedView", bundle: nil)
        self.addChildViewController(feedView)
        self.scrollWindow.addSubview(feedView.view)
        feedView.didMoveToParentViewController(self)
        var feedFrame = feedView.view.frame
        feedFrame.origin.x = self.view.frame.width
        feedView.view.frame = feedFrame
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func previewModeDidStart(movieURL: NSURL) {
        moviePreviewController!.movieURL = movieURL
        moviePreviewController!.previewModeDidStart()
        moviePreviewController!.view.hidden = false
    }
    
    func captureModeDidStart() {
        self.moviePreviewController!.view.hidden = true
        self.captureViewController!.captureModeDidStart()
    }
    
//    func uploadGif(sender: AnyObject) {
//        //Now use image to create into NSData format
//        // upload that to the server
//        let request = Alamofire.upload(.POST, "https://qa.yaychakula.com/api/gif/upload/", file: gifUrl)
//        print(request)
//    }
    
}

