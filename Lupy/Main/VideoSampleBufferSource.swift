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
                             selector: #selector(MoviePreviewViewController.restartVideoFromBeginning),
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
    
    private func getLuminosityFilter(image: CIImage) -> CIImage {
        if luminosity == 0 {
            return image
        }
        print("Luminosity: \(luminosity)")
        if let toneCurveFilter = CIFilter(name: "CIToneCurve") {
            toneCurveFilter.setDefaults()
            toneCurveFilter.setValue(image, forKey: kCIInputImageKey)
            if (luminosity > 0) {
                toneCurveFilter.setValue(CIVector(x: 0.0, y: luminosity), forKey: "inputPoint0")
                toneCurveFilter.setValue(CIVector(x: 0.25, y: luminosity + 0.25 * (1 - luminosity)), forKey: "inputPoint1")
                toneCurveFilter.setValue(CIVector(x: 0.5, y: luminosity + 0.50 * (1 - luminosity)), forKey: "inputPoint2")
                toneCurveFilter.setValue(CIVector(x: 0.75, y: luminosity + 0.75 * (1 - luminosity)), forKey: "inputPoint3")
                toneCurveFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
            } else {
                toneCurveFilter.setValue(CIVector(x: 0.0, y: luminosity), forKey: "inputPoint0")
                toneCurveFilter.setValue(CIVector(x: 0.25, y: luminosity + 0.25 * (1 + luminosity)), forKey: "inputPoint1")
                toneCurveFilter.setValue(CIVector(x: 0.5, y: luminosity + 0.50 * (1 + luminosity)), forKey: "inputPoint2")
                toneCurveFilter.setValue(CIVector(x: 0.75, y: luminosity + 0.75 * (1 + luminosity)), forKey: "inputPoint3")
                toneCurveFilter.setValue(CIVector(x: 1.0, y: 1.0 + luminosity), forKey: "inputPoint4")
            }
            return toneCurveFilter.outputImage!
        }
        return image
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
                let luminousImg = getProcessedImage(pixelBuffer)
                consumer(luminousImg)
            } else {
                // show an alert
                AppDelegate.getAppDelegate().showError("Video Connection Error", message: "Failed to render video")
            }
        }
        
    }
    
    var angleForCurrentTime: Float {
        return Float(NSDate.timeIntervalSinceReferenceDate() % M_PI*2)
    }
    
    func writeVideoToFile(completion: (NSURL?) -> Void){
        dispatch_async(dispatch_queue_create("movie_writer", DISPATCH_QUEUE_SERIAL)) {
            if let (writer, pixelBufferAdaptor) = self.getWriterAndAdaptor(),
                let reader = self.getReader() {
                if self.videoTrack != nil {
                    var isWriting = false
                    let context = CIContext(options: nil)
                    reader.startReading()
                    let readerOutput = reader.outputs.last!
                    while let buffer: CMSampleBuffer? = readerOutput.copyNextSampleBuffer() {
                        if buffer == nil {
                            break
                        }
                        autoreleasepool() {
                            if !isWriting {
                                if writer.startWriting() {
                                    writer.startSessionAtSourceTime(CMSampleBufferGetPresentationTimeStamp(buffer!))
                                    isWriting = true
                                } else {
                                    self.executeCompletionOnMainThread(nil, completion: completion)
                                    return
                                }
                            }
                            let pixelBuffer = CMSampleBufferGetImageBuffer(buffer!)
                            let image = self.getProcessedImage(pixelBuffer!)
                            print("Pixel buffer base address: \(CVPixelBufferGetBaseAddress(pixelBuffer!))")
                            context.render(image, toCVPixelBuffer: pixelBuffer!)
                            while writer.inputs.last!.readyForMoreMediaData == false {
                                NSThread.sleepForTimeInterval(0.05)
                            }
                            let presentationTime = CMSampleBufferGetPresentationTimeStamp(buffer!)
                            pixelBufferAdaptor.appendPixelBuffer(pixelBuffer!, withPresentationTime: presentationTime)
                        }
                    }
                    writer.finishWritingWithCompletionHandler(){
                        self.executeCompletionOnMainThread(writer.outputURL, completion: completion)
                    }
                } else {
                    self.executeCompletionOnMainThread(nil, completion: completion)
                }
            }
        }
    }
    
    private func getReader() -> AVAssetReader? {
        do {
            let asset = self.player!.currentItem!.asset
            let reader = try AVAssetReader(asset: asset)
            let readerOutputSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(unsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            let readerOutput = AVAssetReaderTrackOutput(track: self.videoTrack!, outputSettings: readerOutputSettings)
            reader.addOutput(readerOutput)
            return reader
        } catch {
            return nil
        }
    }
    
    private func getProcessedImage(buffer: CVPixelBuffer) -> CIImage {
        let ciImage = CIImage(CVPixelBuffer: buffer)
        let luminousImage = getLuminosityFilter(ciImage)
        return luminousImage
    }

    
    private func executeCompletionOnMainThread(url: NSURL?, completion: (NSURL?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            print("Done!")
            completion(url)
        }
    }
    
    private func getWriterAndAdaptor() -> (AVAssetWriter, AVAssetWriterInputPixelBufferAdaptor)? {
        let timeInterval = Int(NSDate().timeIntervalSince1970)
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "\(timeInterval).MOV")
        do {
            let writer = try AVAssetWriter(URL: fileURL, fileType: AVFileTypeQuickTimeMovie)
            let videoCompressionProps = [AVVideoAverageBitRateKey as String: videoTrack!.estimatedDataRate]
            let writerOutputSettings: [String: AnyObject] = [AVVideoCodecKey as String: AVVideoCodecH264,
                                                             AVVideoWidthKey as String: videoTrack!.naturalSize.width, // CHANGE THESE IF ORIENTATION IS OFF
                AVVideoHeightKey as String: videoTrack!.naturalSize.height,
                AVVideoCompressionPropertiesKey as String: videoCompressionProps]
            let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: writerOutputSettings, sourceFormatHint: videoTrack!.formatDescriptions.last! as! CMFormatDescription)
            writerInput.expectsMediaDataInRealTime = false
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
            writer.addInput(writerInput)
            return (writer, pixelBufferAdaptor)
        } catch {
            // show error
            return nil
        }
    }
}