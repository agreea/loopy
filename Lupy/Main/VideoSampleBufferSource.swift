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
        CADisplayLink(target: self, selector: #selector(VideoSampleBufferSource.displayLinkDidRefresh(_:)))
    private var videoOutput: AVPlayerItemVideoOutput?
    private let consumer: CIImage -> ()
    private var firstFrames = [CIImage]()
    private var player: AVPlayer?
    private var _luminosity = CGFloat(0.0)
    var luminosity: CGFloat {
        get {
            return _luminosity
        }
        set(newValue) {
            if (newValue > 1.0 || newValue < 0.0){
                return
            }
            synced(self) {
                self._luminosity = CGFloat(newValue - 0.5) / 2.0
                self.frameFilter.luminosity = self._luminosity
            }
        }
    }
    
    private var frameIndex = 0
    private var _frameFilter = FrameFilter()
    var frameFilter: FrameFilter {
        get {
            return _frameFilter
        }
    }
    
    var _filter = VideoFilter.None
    
    var filter: VideoFilter {
        get {
            return _filter
        }
        set(newValue){
            _filter = newValue
            frameFilter.filter = _filter
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
    }
    
    func restartVideoFromBeginning()  {
        let startTime = CMTimeMake(0, 1)
        frameIndex = 0
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
                let image = frameFilter.getProcessedImageFromBuffer(pixelBuffer, frameIndex: frameIndex)
                consumer(image)
            }
            frameIndex += 1
            // if none, render the image. The frame filter will cache it accordingly
        }
    }
    
    func getProcessedImage(image: CIImage, filter: VideoFilter) -> CIImage {
        return frameFilter.getProcessedImageWithFilter(image, filter: filter)
    }
    
    var angleForCurrentTime: Float {
        return Float(NSDate.timeIntervalSinceReferenceDate() % M_PI*2)
    }
}