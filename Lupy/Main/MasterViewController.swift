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
import Alamofire
import CoreData

protocol CoreDataDelegate {
    func getSession() -> String?
    func getUserId() -> Int?
    func getUsername() -> String?
}

protocol TabBarDelegate {
    func goToCamera()
    func goToHome()
    func goToDiscover()
    func goToAlerts()
    func goToUser()
}

protocol CameraNavDelegate {
    func cameraDidExit()
    func cameraDidEnter()
}

class MasterViewController: UIPageViewController, UINavigationControllerDelegate {
    
    var moviePreviewController: MoviePreviewViewController?
    var captureViewController: CaptureViewController?
    var previewMode: Bool = false
    var cameraDelegate: CameraNavDelegate?
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.initCaptureViewController(), self.initFeedViewController(), self.initMyLoopsViewController()]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.dataSource = self
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .Forward,
                               animated: true,
                               completion: nil)
        }
        print("Transition style: \(transitionStyle)")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    private func initMoviePreviewController() -> MoviePreviewViewController {
        moviePreviewController = MoviePreviewViewController(nibName: "MoviePreviewView", bundle: nil)
        moviePreviewController!.captureModeDelegate = self
        moviePreviewController!.view.hidden = true
        return moviePreviewController!
    }
    
    private func initCaptureViewController() -> CaptureViewController {
        captureViewController = CaptureViewController(nibName: "CaptureViewController", bundle: nil)
        captureViewController!.captureModeDelegate = self
        initMoviePreviewController()
        captureViewController!.view.addSubview(moviePreviewController!.view)
        moviePreviewController!.coreDataDelegate = self
        return captureViewController!
    }
    
    private func initFeedViewController() -> FeedViewController {
        let feedViewController = FeedViewController(nibName: "FeedViewController", bundle: nil)
        return feedViewController
    }

    private func initMyLoopsViewController() -> ProfileViewController {
        let myLoopsViewController = ProfileViewController(nibName: "FeedViewController", bundle: nil)
        if let userId = AppDelegate.getAppDelegate().getUserId() {
            myLoopsViewController.configProfileByUserId(userId, backButtonMethod: nil)
        }
        return myLoopsViewController
    }
    
    func goToCapture(direction: UIPageViewControllerNavigationDirection) {
        setViewControllers([orderedViewControllers[0]], direction: direction, animated: true, completion: nil)
    }
    
    func goToFeed(direction: UIPageViewControllerNavigationDirection) {
        setViewControllers([orderedViewControllers[1]], direction: direction, animated: true, completion: nil)
    }

    func goToMyLoops(direction: UIPageViewControllerNavigationDirection) {
        // okay sure whats good
        setViewControllers([orderedViewControllers[2]], direction: direction, animated: true, completion: nil)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        goToHome()
    }
    func pageViewController(pageViewController: UIPageViewController,
                            viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController,
                            viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MasterViewController: TabBarDelegate {
    func goToCamera() {
        setViewControllers([orderedViewControllers[0]], direction: .Reverse, animated: false, completion: nil)
        cameraDelegate?.cameraDidEnter()
    }
    
    func goToHome() {
        if let feedVC = orderedViewControllers[1] as? FeedViewController {
            feedVC.showNavBarImmediately()
            setViewControllers([orderedViewControllers[1]], direction: .Reverse, animated: false, completion: nil)
        }
    }
    
    func goToDiscover() {
    }
    
    func goToAlerts() {
    }
    
    func goToUser() {
        setViewControllers([orderedViewControllers[2]], direction: .Reverse, animated: false, completion: nil)
    }
}

extension MasterViewController: CoreDataDelegate {
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

extension MasterViewController: CaptureModeDelegate {
    // CaptureModeDelegateMethods
    func previewModeDidStart(movieURL: NSURL) {
        moviePreviewController!.movieURL = movieURL
        moviePreviewController!.previewModeDidStart()
        moviePreviewController!.view.hidden = false
        previewMode = true
    }
    
    
    func captureModeDidStart() {
        self.moviePreviewController!.view.hidden = true
        self.captureViewController!.captureModeDidStart()
        previewMode = false
    }
    
    func didFinishUpload() {
        // go to feed?
        goToHome()
        if let feedViewController = orderedViewControllers[1] as? FeedViewController {
            feedViewController.attemptLoadFeed()
        }
        moviePreviewController!.view.hidden = true
        cameraDelegate?.cameraDidExit()
    }
    
    func didExitCamera() {
        cameraDelegate?.cameraDidExit()
        goToHome()
    }
    
    func didEnterCamera() {
        cameraDelegate?.cameraDidEnter()
    }
}

