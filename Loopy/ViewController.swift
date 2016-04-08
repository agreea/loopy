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
import CoreData

protocol CoreDataDelegate {
        func getSession() -> String?
        func getUserId() -> Int?
        func getUsername() -> String?
}
class ViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate, CaptureModeDelegate, CoreDataDelegate {
    
    @IBOutlet weak var scrollWindow: UIScrollView!
    var moviePreviewController: MoviePreviewViewController?
    var captureViewController: CaptureViewController?
    var previewMode: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        initCaptureViewController()
        initFeedViewController()
        initMoviePreviewController()
        scrollWindow.contentSize = CGSizeMake(self.view.frame.width * 2, self.view.frame.size.height)
        scrollWindow.showsHorizontalScrollIndicator = false
        scrollWindow.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    private func initMoviePreviewController(){
        moviePreviewController = MoviePreviewViewController(nibName: "MoviePreviewView", bundle: nil)
        moviePreviewController!.captureModeDelegate = self
        self.addChildViewController(moviePreviewController!)
        moviePreviewController!.view.hidden = true
        captureViewController!.view.addSubview(moviePreviewController!.view)
        moviePreviewController!.didMoveToParentViewController(self)
        moviePreviewController!.coreDataDelegate = self

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
        feedView.coreDataDelegate = self
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if previewMode {
            scrollView.contentOffset.x = 0
        }
    }
    
    func previewModeDidStart(movieURL: NSURL) {
        moviePreviewController!.movieURL = movieURL
        moviePreviewController!.previewModeDidStart()
        moviePreviewController!.view.hidden = false
        previewMode = true
        
    }
    
    // CaptureModeDelegateMethods
    func captureModeDidStart() {
        self.moviePreviewController!.view.hidden = true
        self.captureViewController!.captureModeDidStart()
        previewMode = false
    }
    
    // CoreDataDelegateMethods
    func getUserId() -> Int? {
        if let userData = getUserData() {
            return userData.valueForKey("id") as? Int
        }
        return nil
    }
    
    func getSession() -> String? {
        if let userData = getUserData() {
            return userData.valueForKey("session") as? String
        }
        return nil
    }
    
    func getUsername() -> String? {
        if let userData = getUserData() {
            return userData.valueForKey("username") as? String
        }
        return nil
    }
    
    private func getUserData() -> NSManagedObject? {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "User_data")
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest)
            if let userCredentials = results as? [NSManagedObject],
                let userData = userCredentials[0] as? NSManagedObject {
                return userData
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return nil
    }

}

