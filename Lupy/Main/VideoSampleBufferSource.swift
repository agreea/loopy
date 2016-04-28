//
//  Library.swift
//  CoreImageVideo
//
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation
import AVFoundation
import GLKit

let pixelBufferDict: [String: AnyObject] =
    [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

func synced(lock: AnyObject, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

class VideoSampleBufferSource: NSObject {
    lazy var displayLink: CADisplayLink =
        CADisplayLink(target: self, selector: "displayLinkDidRefresh:")
    
    private var videoOutput: AVPlayerItemVideoOutput?
    private let consumer: CIImage -> ()
    private var player: AVPlayer?
    private var luminosity = CGFloat(0.0)
    var filter = VideoFilter.None
    var filterSettings: FilterSettings {
        get {
            return FilterSettings(luminosity: self.luminosity, filter: self.filter)
        }
    }

    var videoTrack: AVAssetTrack? {
        get {
           return player!.currentItem?.asset.tracksWithMediaType(AVMediaTypeVideo).last
        }
    }
    var rendering = false
    
    init?(consumer callback: CIImage -> ()) {
        consumer = callback
        super.init()
        //set a listener for when the video ends
    }
    
    func restartVideoFromBeginning()  {
        let startTime = CMTimeMake(0, 1)
        player!.seekToTime(startTime)
        player!.play()
    }

    func start(url: NSURL) {
        if rendering {
            return
        }
        print("Started")
        if player == nil {
            player = AVPlayer(URL: url)
            player!.actionAtItemEnd = .None
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferDict)
            player!.currentItem!.addOutput(videoOutput!)
            NSNotificationCenter
                .defaultCenter()
                .addObserver(self,
                             selector: #selector(VideoSampleBufferSource.restartVideoFromBeginning),
                             name: AVPlayerItemDidPlayToEndTimeNotification,
                             object: player!.currentItem)
        } else {
            let playerItem = AVPlayerItem(URL: url)
            player!.replaceCurrentItemWithPlayerItem(playerItem)
        }
        rendering = true
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        displayLink.paused = false
        player!.play()
    }
    
    //
    func setLuminosity(value: Float) {
        if (value > 1.0 || value < 0.0){
            return
        }
        synced(self) {
            self.luminosity = CGFloat(1.3 * (value - 0.5))
        }
    }
    
    func stop() {
        if !rendering {
            return
        }
        player!.pause()
        displayLink.paused = true
        displayLink.invalidate()
        rendering = false
        print("Stopped!")
    }
    
    func displayLinkDidRefresh(link: CADisplayLink) {
        let itemTime = videoOutput!.itemTimeForHostTime(CACurrentMediaTime())
        if videoOutput!.hasNewPixelBufferForItemTime(itemTime) {
            var presentationItemTime = kCMTimeZero
            if let pixelBuffer = videoOutput!.copyPixelBufferForItemTime(itemTime, itemTimeForDisplay: &presentationItemTime) {
                let image = FrameFilter.getProcessedImage(pixelBuffer, filterSettings: filterSettings)
                consumer(image)
            } else {
                // show an alert
                AppDelegate.getAppDelegate().showError("Video Connection Error", message: "Failed to render video")
            }
        }
        
    }
    
    func getProcessedImage(image: CIImage, filter: VideoFilter) -> CIImage {
        let filterSettings = FilterSettings(luminosity: luminosity, filter: filter)
        return FrameFilter.getProcessedImage(image, filterSettings: filterSettings)
    }
    
    var angleForCurrentTime: Float {
        return Float(NSDate.timeIntervalSinceReferenceDate() % M_PI*2)
    }
}