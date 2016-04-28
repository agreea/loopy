//
//  FeedView.swift
//  Loopy
//
//  Created by Agree Ahmed on 3/21/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import MobileCoreServices
import CoreData
import AVFoundation

struct FeedItem {
    let Id: Int?
    let User_id: Int?
    let Username: String?
    let Uuid: String?
    let Timestamp: String?
    let Liked: Bool?
}
struct ScrollSession {
    let originY: CGFloat?
    var currentY: CGFloat?
    var delta: CGFloat? {
        get {
            return currentY! - originY!
        }
    }
}
enum UploadState {
    case None, Uploading, Error, Success
}
class FeedViewController: UIViewController {
    // function: view:
    var feedData = [FeedItem]()
    var scrolling = false
    var decelerating = false
    var refreshControl: UIRefreshControl!
    var id: Int?
    var navbarFullHeight: CGFloat?
    var scrollSession: ScrollSession?
    var uploadState = UploadState.None
    var uploaderDelegate: VideoUploaderDelegate?
    
    @IBOutlet weak var imageCopiedAlert: UILabel!
    @IBOutlet weak var feedView: UITableView!
    
    // Navbar Components
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var navBarHeight: NSLayoutConstraint!
    @IBOutlet weak var leftButtonNav: UIButton!
    @IBOutlet weak var rightButtonNav: UIButton!
    @IBOutlet weak var titleNav: UILabel!
    var navBarVanishes = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navbarFullHeight = abs(navBarHeight.constant)
        let postNib = UINib(nibName: "FeedCell", bundle: nil)
        let uploadingNib = UINib(nibName: "UploadingCell", bundle: nil)
        id = AppDelegate.getAppDelegate().getUserId()
        feedView.registerNib(postNib, forCellReuseIdentifier: "feedCell")
        feedView.registerNib(uploadingNib, forCellReuseIdentifier: "uploadingCell")
        feedView.tableFooterView = UIView()
        feedView.allowsSelection = false
        
        attemptLoadFeed()
        imageCopiedAlert.layer.cornerRadius = 6.0
        imageCopiedAlert.clipsToBounds = true
        setUpPullToRefresh()
        addNavbarTitleGesture()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setUpPullToRefresh() {
        feedView.separatorStyle = UITableViewCellSeparatorStyle.None
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refresh feed")
        refreshControl.addTarget(self, action: #selector(FeedViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        feedView.addSubview(self.refreshControl) // not required when using UITableViewController
        refreshControl.superview!.sendSubviewToBack(refreshControl)
    }
    
    func addNavbarTitleGesture() {
        let navbarTitleListener = UITapGestureRecognizer()
        navbarTitleListener.numberOfTapsRequired = 1
        navbarTitleListener.addTarget(self, action: #selector(FeedViewController.scrollToTop))
        titleNav.addGestureRecognizer(navbarTitleListener)
    }
    
    func scrollToTop() {
        feedView.setContentOffset(CGPointZero, animated:true)
    }
    
    func refresh(sender: AnyObject) {
        // Code to refresh table view
        attemptLoadFeed()
    }
    
    func attemptLoadFeed() {
        if let session = AppDelegate.getAppDelegate().getSession() {
            loadFeed(session)
        } else {
            AppDelegate.getAppDelegate().showError("Log in Error", message: "Please make sure you're logged in")
        }
    }
    
    func loadFeed(session: String) {
        // Do any additional setup after loading the view.
        let parameters = [
            "method": "GetFeed",
            "session": session
        ]
        Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
            parameters: parameters)
            .responseJSON { response in
                self.processFeedAPIResponse(response)
        }
    }
    
    func processFeedAPIResponse(response: Response<AnyObject, NSError>) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showError("Connection Error", message: "Failed to load feed")
            self.refreshControl.endRefreshing()
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"] == 1 {
                let jsonArray = json["Return"].arrayValue
                constructFeedArrayFromJSON(jsonArray)
                self.feedView!.reloadData()
                print("Reloaded data")
            } else {
                print("Error: \(json["Error"])")
                AppDelegate.getAppDelegate().showError("Feed Error", message: json["Error"].stringValue)
            }
        }
        self.refreshControl.endRefreshing()
    }
    
    func constructFeedArrayFromJSON(jsonArray: [JSON]) {
        feedData = [FeedItem]()
        for jsonItem in jsonArray {
            let feedItem = constructFeedItemFromJSON(jsonItem)
            feedData.append(feedItem)
        }
    }
    
    private func constructFeedItemFromJSON(json: JSON) -> FeedItem {
        let feedItem = FeedItem(Id: json["Id"].int,
                                User_id: json["User_id"].int,
                                Username: json["Username"].string,
                                Uuid: json["Uuid"].string,
                                Timestamp: json["Timestamp"].string,
                                Liked: json["User_liked"].bool)
        return feedItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // to load the GIF to the clipboard
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    @IBAction func didPressLeftButtonNav(sender: AnyObject) {
        navBarLeftButtonAction()
    }
    
    @IBAction func didPressRightButtonNav(sender: AnyObject) {
        navBarRightButtonAction()
    }
    
    func navBarRightButtonAction() {
        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
        contactViewController.configureUserList(AddContactsViewController.CONFIG_CONTACTS) {
            self.dismissViewControllerAnimated(true){}
        }
        self.presentViewController(contactViewController, animated: true, completion: nil)
    }

    func navBarLeftButtonAction() {
//        if let masterController = self.parentViewController as? MasterViewController? {
//            masterController?.goToCapture(.Reverse)
//        }
    }
    
    func showImageCopying() {
        imageCopiedAlert.text = "Copying gif to clipboard..."
        imageCopiedAlert.backgroundColor = UIColor(netHex: 0xDB8EFF)
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.imageCopiedAlert.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func showImageCopied() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.imageCopiedAlert.backgroundColor = UIColor(netHex: 0x7E00FF)
            self.view.layoutIfNeeded()
            }, completion: { finished in
                if finished {
                    self.imageCopiedAlert.text = "Gif copied!"
                    self.startImageCopiedFadeout()
                }
            })
    }
    
    func startImageCopiedFadeout() {
        UIView.animateWithDuration(0.6, delay: 1.8, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.imageCopiedAlert.alpha = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // Each feedCell must request to download a gif
    // if the user is scrolling or the cell is no longer visible, say no
    func canCellDownloadGif(cell: UITableViewCell) -> Bool {
        if decelerating {
            return false
        }
        if let cellIndex = feedView.indexPathForCell(cell) {
            for indexPath in feedView.indexPathsForVisibleRows! {
                if indexPath.row == cellIndex.row {
                    return true
                }
            }
            return false
        }
        return true
    }
    
    func uploadDidStart() {
        uploadState = .Uploading
        feedView.reloadData()
    }
    
    func uploadDidSucceed() {
        uploadState = .None
        if let session = AppDelegate.getAppDelegate().getSession() {
            loadFeed(session)
        } else {
            AppDelegate.getAppDelegate().showError("Feed Refresh Error", message: "Make Sure your are logged in and try again")
        }
    }

    func uploadError() {
        // show that and allow the user to tap to try again
        uploadState = .Error
        feedView.reloadData()
    }
    
}

extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldShowUploadingCell() && section == 0 {
            return 1
        }
        return feedData.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if shouldShowUploadingCell() && indexPath.section == 0 {
            return CGFloat(60.0)
        }        
        return view.frame.width * 1.25 + 50.0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if shouldShowUploadingCell() {
            return 2
        } else {
            return 1
        }
    }
    
    func shouldShowUploadingCell() -> Bool {
        return uploadState == .Uploading || uploadState == .Error
    }
    // download gif, copy it to clipboard
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        feedView.deselectRowAtIndexPath(indexPath, animated: true)
//        let feedItem = feedData[indexPath.row]
//        let gifUrl = "https://yaychakula.com/img/" + feedItem.Uuid! + "/loopy.gif"
//        showImageCopying()
//        Alamofire.request(.GET, gifUrl).response { (request, response, gifData, error) in
//            let pasteBoard = UIPasteboard.generalPasteboard()
//            pasteBoard.setData(gifData!, forPasteboardType: kUTTypeGIF as String)
//            self.showImageCopied()
//            print("Download Finished")
//        }
//    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if shouldShowUploadingCell() && indexPath.section == 0 {
            let cell = feedView.dequeueReusableCellWithIdentifier("uploadingCell") as! UploadingCell
            cell.errorState = uploadState == .Error
            cell.delegate = self
            return cell
        }
        let feedItem = self.feedData[indexPath.row]
        let cell = feedView.dequeueReusableCellWithIdentifier("feedCell") as! FeedCell
        cell.feedViewController = self
        cell.hasGif = false
        cell.delegate = self
        cell.loadItem(feedItem, userId: id!)
        cell.alpha = 1.0
        return cell
    }
    
    // methods to manage video loading
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView){
        let currentY = scrollView.contentOffset.y
        scrollSession = ScrollSession(originY: currentY, currentY: currentY)
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // if the navbar is half its height --> hide it
        print("ScrollEnd. NavHeight: \(navBar.frame.height)")
        print("ScrollEnd. CurrentY: \(scrollSession!.currentY)")
        if abs(navBarHeight.constant) * 2 < navbarFullHeight! {
            print("Hiding navbar")
            hideNavBar()
        } else {
            showNavBarHeight(navbarFullHeight!)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollPos = scrollView.contentOffset
        scrollSession!.currentY = scrollPos.y
        resizeNavBar()
        updateLoopStatusForVisibleCells()
    }
    
    private func updateLoopStatusForVisibleCells() {
        // get all the visible cells
        // for each one if less than half of the gifVideo is visible, pause that video
        if let cells = feedView.visibleCells as? [FeedCell] {
            for cell in cells {
                let indexPath = feedView.indexPathForCell(cell)
                let rect = feedView.rectForRowAtIndexPath(indexPath!)
                
                // get the view's frame in terms of the screen
                let cellTop = rect.origin.y
                let loopTop = cellTop + cell.gifPreview.frame.origin.y
                let loopH = cell.gifPreview.frame.height
                let loopBottom = loopTop + loopH
                let feedTop = scrollSession!.currentY!
                let feedBottom = scrollSession!.currentY! + feedView.frame.height
                if loopTop < feedTop {
                    if loopBottom - feedTop < loopH/2 { // if more than half of the video is hidden, pause it
                        cell.pauseVideo()
                        cell.alpha = (loopBottom - feedTop)/(loopH/2)
                    } else {
                        cell.alpha = 1.0
                        cell.playVideo()
                    }
                } else if feedBottom < loopBottom  { // for videos with top half showing
                    if feedBottom - loopTop < loopH/2 {
                        cell.pauseVideo()
                    } else {
                        cell.playVideo()
                    }
                }
            }
        }
    }
    
    private func resizeNavBar() {
        if !navBarVanishes {
            return
        }
        if scrollSession!.currentY < navbarFullHeight! {
            showNavBarHeight(navbarFullHeight!)
        }
        if scrollSession!.delta! < 0 { // scrolling up
            growNavBar()
        } else { // scrolling down
            shrinkNavBar()
        }
    }
    
    private func shrinkNavBar() {
        if navBarHeight.constant == 0.0 {
            return
        }
        let midScrollHeight = navbarFullHeight! - abs(scrollSession!.delta!)
        // prevent passing showNavBarHeight a negative value
        let barHeight = max(midScrollHeight, 0.0)
        print("shrinkNav, midScrollH: \(midScrollHeight)")
        showNavBarHeight(barHeight)
    }
    
    private func growNavBar() {
        if navBar.frame.height == navbarFullHeight {
            return
        }
        let delta = scrollSession!.delta!
        if abs(delta) > navbarFullHeight! {
            let midScrollHeight = abs(delta) - navbarFullHeight!
            // prevent oversized navbar
            let barHeight = min(midScrollHeight, navbarFullHeight!)
            showNavBarHeight(barHeight)
        }
    }
    
    private func hideNavBar() {
        print("Hiding navbar")
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.navBarHeight.constant = 0.0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func showNavBarHeight(height: CGFloat) {
        UIView.animateWithDuration(0.01, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.navBarHeight.constant = height * -1
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func showNavBarImmediately() {
        if self.navbarFullHeight != nil {
            self.navBarHeight.constant = -1 * self.navbarFullHeight!
            self.view.layoutIfNeeded()
        }
    }
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        decelerating = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        decelerating = false
        // for all visible cells that don't have a gif, set their gifs
        for cell in feedView.visibleCells {
            let index = feedView.indexPathForCell(cell)
            if index!.row > feedData.count - 1 {
                return
            }
            let feedItem = feedData[index!.row]
            if let otherCell = cell as? FeedCell {
                if !otherCell.hasGif {
                    otherCell.setImagePreview(feedItem.Uuid!)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView,
                   didEndDisplayingCell cell: UITableViewCell,
                    forRowAtIndexPath indexPath: NSIndexPath) {
        if let feedCell = cell as? FeedCell {
            feedCell.gifPreview.kf_cancelDownloadTask()
            feedCell.hideVideo()
        }
    }
}

extension FeedViewController: FeedCellDelegate {
    
    func usernameTapped(username: String) {
        let profileViewController = ProfileViewController(nibName: "FeedViewController", bundle: nil)
        profileViewController.configProfileByUsername(username) {
            let outTransition = FeedViewController.getModalViewTransition()
            outTransition.subtype = kCATransitionFromLeft
            profileViewController.view.window!.layer.addAnimation(outTransition, forKey: nil)
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        let transition = FeedViewController.getModalViewTransition()
        transition.subtype = kCATransitionFromRight
        self.view.window!.layer.addAnimation(transition, forKey:nil)
        self.presentViewController(profileViewController, animated: false, completion: nil)
    }
    
    class func getModalViewTransition() -> CATransition {
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionPush
        return transition
    }
    
    func likePost(id: Int, cell: FeedCell) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "Id": "\(id)",
                "method": "Like"
            ]
            executeChangeLikeStatus(params, cell: cell)
        }
    }
    
    func unlikePost(id: Int, cell: FeedCell) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "Id": "\(id)",
                "method": "Unlike"
            ]
            executeChangeLikeStatus(params, cell: cell)
        }
    }
    
    private func executeChangeLikeStatus(params: [String : String], cell: FeedCell) {
        Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif",
            parameters: params)
            .responseJSON { response in
                self.processChangeLikeStatusRepsonse(response, cell: cell, params: params)
        }
    }
    
    private func processChangeLikeStatusRepsonse(response: Response<AnyObject, NSError>, cell: FeedCell, params: [String: String]) {
        guard response.result.error == nil else {
            // got an error in getting the data, need to handle it
            print(response.result.error!)
            AppDelegate.getAppDelegate().showError("Connection Error", message: "Failed to record like/unlike")
            return
        }
        if let value: AnyObject = response.result.value {
            let json = JSON(value)
            if json["Success"].int == 1 {
                // update the table view data and cell
                let nowLiked = params["method"]!.hasPrefix("Like")
                let feedItemId = Int(params["Id"]!)
                updateFeedData(feedItemId!, nowLiked: nowLiked)
                cell.liked = nowLiked
            } else {
                AppDelegate.getAppDelegate().showError("Error", message: "Failed to record like/unlike")
            }
        }
    }
    
    private func updateFeedData(feedItemId: Int, nowLiked: Bool) {
        for i in 0...feedData.count-1 {
            let feedItem = feedData[i]
            if feedItem.Id == feedItemId {
                feedData[i] = FeedItem(Id: feedItem.Id,
                                        User_id: feedItem.User_id,
                                        Username: feedItem.Username,
                                        Uuid: feedItem.Uuid,
                                        Timestamp: feedItem.Timestamp,
                                        Liked: nowLiked)
            }
        }
        feedView.reloadData()
    }

}

extension FeedViewController: UploadingCellDelegate {
    func retry() {
        uploaderDelegate!.retry()
    }
    
    func cancelUpload() {
        uploadState = .None
        feedView.reloadData()
    }
}