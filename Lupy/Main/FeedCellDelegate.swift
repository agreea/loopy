//
//  FeedCellDelegate.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/30/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Regift
import AVFoundation
import Photos

enum ReportReason {
    case Bullying, Adult
}

extension FeedViewController: FeedCellDelegate {
    func getTempURLForKey(contentKey: String) -> NSURL {
        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let movieName = contentKey + ".MOV"
        return tempDir.URLByAppendingPathComponent(movieName)
    }
    
    func getFeedItemForCell(cell: FeedCell) -> FeedItem {
        let indexPath = feedView.indexPathForCell(cell)
        return feedData[indexPath!.row]
    }
    
    func usernameTapped(cell: FeedCell) {
        let feedItem = getFeedItemForCell(cell)
        let profileViewController = ProfileViewController(nibName: "FeedViewController", bundle: nil)
        profileViewController.configProfileByUsername(feedItem.Username!) {
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
    
    func didPressMore(cell: FeedCell) {
        let feedItem = getFeedItemForCell(cell)
        if isSelfPost(cell) {
            presentDeleteAlertController(feedItem)
        } else {
            presentReportAlertController(feedItem)
        }
    }

    private func presentDeleteAlertController(feedItem: FeedItem) {
        let alertController = UIAlertController(title: "Delete Post?", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
            self.presentDeleteConfirmation(feedItem.Id!)
        })
        alertController.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func presentDeleteConfirmation(id: Int) {
        let alertController = UIAlertController(title: "Delete Post", message: "This will be forever-ever.", preferredStyle: UIAlertControllerStyle.Alert)
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
            self.deletePost(id)
        })
        alertController.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func presentReportAlertController(feedItem: FeedItem) {
        let alertController = UIAlertController(title: "Report Post?", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let deleteAction = UIAlertAction(title: "Report", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
            self.presentReportConfirmation(feedItem.Id!)
        })
        alertController.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func presentReportConfirmation(id: Int) {
        let alertController = UIAlertController(title: "Report Post?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        let reportAction = UIAlertAction(title: "Report", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
            //            self.reportPost(feedItem.Id!)
        })
        alertController.addAction(reportAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(alert :UIAlertAction!) in
            print("cancel button tapped")
        })
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }

    func isSelfPost(cell: FeedCell) -> Bool {
        let feedItem = getFeedItemForCell(cell)
        return feedItem.User_id! == self.myUserId!
    }
    
    
    func downloadPost(cell: FeedCell) {
        // save video to file using the recursive lofi structure
        // add a completion and call it once this method is done
    }
    
    func savePostToCameraRoll(cell: FeedCell) {
        // get URL for video
        let feedItem = getFeedItemForCell(cell)
        let contentKey = getContentKeyForFeedItem(feedItem)
        let videoURL  = getTempURLForKey(contentKey)
        downsampleVideoForCameraRoll(videoURL)
    }
    
    func getContentKeyForFeedItem(feedItem: FeedItem) -> String {
        return feedItem.Username! + "_" + feedItem.Uuid!
    }
    
    private func downsampleVideoForCameraRoll(url: NSURL) {
        let asset = AVAsset(URL: url)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, 60)
        let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last!
        
        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width/1.5, videoTrack.naturalSize.width * 1.25/1.5)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let scale = CGAffineTransformMakeScale(0.75, 0.75)
        transformer.setTransform(scale, atTime: kCMTimeZero)
        
        instruction.layerInstructions = NSArray(object: transformer) as! [AVVideoCompositionLayerInstruction]
        videoComposition.instructions = NSArray(object: instruction) as! [AVVideoCompositionInstructionProtocol]
        let timeInterval = Int(NSDate().timeIntervalSince1970)
        let exportURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "\(timeInterval).MOV")
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter!.videoComposition = videoComposition
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.outputURL = exportURL
        exporter!.exportAsynchronouslyWithCompletionHandler({
            self.writeVideoToGifForCameraRoll(exporter!.outputURL!)
        })        // TODO: error check

    }
    
    func writeVideoToGifForCameraRoll(url: NSURL) {
        let asset = AVAsset(URL: url)
        let startTime = Float(0.0)
        let duration  = Float(asset.duration.seconds)
        if let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last {
            let frameRate = min(Int(videoTrack.nominalFrameRate * 0.75), 22)
            print("Frame rate: \(videoTrack.nominalFrameRate)")
            dispatch_async(dispatch_queue_create("gif_writer", DISPATCH_QUEUE_SERIAL)) {
                Regift.createGIFFromSource(url, startTime: startTime, duration: duration, frameRate: frameRate) { (destURL) in
                    if destURL == nil {
                        // show some error
                        dispatch_async(dispatch_get_main_queue()) {
                            AppDelegate.getAppDelegate().showError("Gif Save Error", message: "Couldn't save the loop to your library! :(")
                        }
                        return
                    }
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(destURL!)
                        }, completionHandler: { (success, error) in
                            if success {
                                print("Was successful!!")
                            } else {
                                print("Failed to save: \(error)")
                            }
                    })
                }
            }
        } else {
            AppDelegate.getAppDelegate().showError("Download Failure", message: "Couldn't save the loop to your library! :(")
        }
    }
    
    func deletePost(id: Int) {
        if let session =  AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "Id": "\(id)",
                "method": "Delete"
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif",
                parameters: params)
                .responseJSON { response in
                    API.processResponse(response, onSuccess: self.processDeletePostResult)
            }
        }
    }
    
    func processDeletePostResult(value: AnyObject) {
        let json = JSON(value)
        let appDelegate = AppDelegate.getAppDelegate()
        if json["Success"].int == 1 {
            loadFeed(appDelegate.getSession()!)
        } else {
            AppDelegate.getAppDelegate().showError("Error", message: "Failed to delete file")
        }
    }
    
    func reportPost(cell: FeedCell, reason: ReportReason) {
        var reportReasonString: String?
        switch(reason) {
        case .Bullying:
            reportReasonString = "Bullying"
            break
        case .Adult:
            reportReasonString = "Adult"
        }
        let feedItem = getFeedItemForCell(cell)
        if let session = AppDelegate.getAppDelegate().getSession() {
            let params = [
                "session": session,
                "Id": "\(feedItem.Id!)",
                "method": "Report"
            ]
            Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif",
                parameters: params)
                .responseJSON { response in
                    self.processChangeLikeStatusRepsonse(response, cell: cell, params: params)
            }
        }
    }
    
    /*
     ============= LIKE AND UNLIKE =============
     */
    
    func likePost(cell: FeedCell) {
        let feedItem = getFeedItemForCell(cell)
        if let session = AppDelegate.getAppDelegate().getSession(),
                postId = feedItem.Id {
            let params = [
                "session": session,
                "Id": "\(postId)",
                "method": "Like"
            ]
            executeChangeLikeStatus(params, cell: cell)
        } else {
            // show error
        }
    }
    
    func unlikePost(cell: FeedCell) {
        let feedItem = getFeedItemForCell(cell)
        if let session = AppDelegate.getAppDelegate().getSession(),
                postId = feedItem.Id {
            let params = [
                "session": session,
                "Id": "\(postId)",
                "method": "Unlike"
            ]
            executeChangeLikeStatus(params, cell: cell)
        } else {
            // show error
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
//            cell.playerLayer?.hidden = true
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
//        feedView.reloadData()
    }
    
}

extension FeedViewController {
    // get playerItem(cell)
    /*
        // fetch video
        // once that's ready, set the cell's playerLayerPlayer
     */
    func loadVideo(contentKey: String, cell: FeedCell) {
        // check if the video file is in the temporary directory
        let moviePath = getTempURLForKey(contentKey)
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(moviePath.path!) {
            let playerItem = AVPlayerItem(URL: moviePath)
            let duration = playerItem.asset.duration
            if duration != CMTimeMake(0, 1) {
                print("serving cache")
                cell.videoLoaded(moviePath)
                return
            }
        } else {
            fetchVideoFromServer(contentKey, cell: cell)
        }
    }

    // fine
    private func fetchVideoFromServer(contentKey: String, cell: FeedCell) {
        let videoUrl = "https://s3.amazonaws.com/keyframecontent/" + contentKey + "/v.MOV"
        Alamofire.request(.GET, videoUrl).response { request, response, data, error in
            print("For \(contentKey), Fetched bytes: \(data!.length)")
            if let movieURL = self.writeVideoFile(contentKey, data: data!) {
                cell.videoLoaded(movieURL)
            } else {
                print("failed to fetch")
            }
        }
    }

    private func writeVideoFile(contentKey: String, data: NSData) -> NSURL? {
        let moviePath = getTempURLForKey(contentKey)
        do {
            try data.writeToFile(moviePath.path!, options: .AtomicWrite)
        } catch {
            print("\(error)")
        }
        let manager = NSFileManager.defaultManager()
        return manager.fileExistsAtPath(moviePath.path!) ? moviePath : nil
    }
    
}
























