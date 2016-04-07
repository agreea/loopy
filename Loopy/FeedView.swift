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

struct FeedItem {
    let Id: Int?
    let User_id: Int?
    let Username: String?
    let Uuid: String?
    let Timestamp: String?
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: Float) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(a))
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff, a: 1.0)
    }
    convenience init(netHex:Int, alpha: Float) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff, a: alpha)
    }
}
class FeedView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // function: view:
    var feedData = [FeedItem]()
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var imageCopiedAlert: UILabel!
    @IBOutlet weak var feedView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "FeedCell", bundle: nil)
        feedView.registerNib(nib, forCellReuseIdentifier: "feedCell")
        loadFeed()
        imageCopiedAlert.layer.cornerRadius = 6.0
        imageCopiedAlert.clipsToBounds = true
        setUpPullToRefresh()
    }
    
    func setUpPullToRefresh() {
        feedView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Refresh feed")
        self.refreshControl.addTarget(self, action: #selector(FeedView.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        feedView.addSubview(self.refreshControl) // not required when using UITableViewController
    }
    
    func refresh(sender: AnyObject) {
        // Code to refresh table view
        feedData = [FeedItem]()
        loadFeed()
    }
    
    func loadFeed() {
        // Do any additional setup after loading the view.
        let parameters = [
            "method": "GetFeed",
            "session": "c2dc4cc4-08cb-4c18-be8b-6d8ef0c812cc"
        ]
        Alamofire.request(.POST, "https://qa.yaychakula.com/api/gif_user",
            parameters: parameters)
            .responseJSON { response in
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    print(response.result.error!)
                    return
                }
                if let value: AnyObject = response.result.value {
                    let json = JSON(value)
                    self.constructFeedDataFromJSON(json)
                    self.feedView!.reloadData()
                    self.refreshControl.endRefreshing()
                }
        }
    }
    
    func constructFeedDataFromJSON(json: JSON) {
        print("\(json)")
        if json["Error"] != "" {
            print("Error: \(json["Error"])")
            return
        }
        let jsonArray = json["Return"].arrayValue
        for jsonItem in jsonArray {
            let feedItem = constructFeedItemFromJSON(jsonItem)
            feedData.append(feedItem)
        }
        print("\(feedData)")
    }
    
    private func constructFeedItemFromJSON(json: JSON) -> FeedItem {
        let feedItem = FeedItem(Id: json["Id"].int,
                                User_id: json["User_id"].int,
                                Username: json["Username"].string,
                                Uuid: json["Uuid"].string,
                                Timestamp: json["Timestamp"].string)
        return feedItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedData.count
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        feedView.deselectRowAtIndexPath(indexPath, animated: true)
        let feedItem = feedData[indexPath.row]
        let gifUrl = "https://yaychakula.com/img/" + feedItem.Uuid! + "/loopy.gif"
        showImageCopying()
        Alamofire.request(.GET, gifUrl).response { (request, response, gifData, error) in
            let pasteBoard = UIPasteboard.generalPasteboard()
            pasteBoard.setData(gifData!, forPasteboardType: kUTTypeGIF as String)
            self.showImageCopied()
            print("Download Finished")
        }
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = feedView.dequeueReusableCellWithIdentifier("feedCell") as! FeedCell
        print("got cell")
        
        let feedItem = self.feedData[indexPath.row]
        cell.loadItem(feedItem)
        return cell
    }

}
