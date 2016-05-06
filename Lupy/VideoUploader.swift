//
//  VideoUploader.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/27/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import AVFoundation
import GLKit
import Alamofire
import SwiftyJSON

protocol VideoUploaderDelegate {
    func uploadDidStart(firstFrame: CIImage)
    func uploadDidSucceed()
    func uploadDidError()
    func retry()
}

class VideoUploader: NSObject {
    
    private var videoOutput: AVPlayerItemVideoOutput?
    private var player: AVPlayer?
    private var delegate: VideoUploaderDelegate
    var sourceURL: NSURL?
    private var filterSettings: FilterSettings?
    private var firstFrame: CIImage?
    let context = CIContext(options:nil)

    init?(delegate: VideoUploaderDelegate){
        self.delegate = delegate
        super.init()
    }
    
    func postVideo(sourceURL: NSURL, filterSettings: FilterSettings){
        self.sourceURL = sourceURL
        self.filterSettings = filterSettings
        writeFilteredVideoToFile()
        // writeFilteredVideoToFile
        // once that's started, send delegate the first frame
        // once it's done, post the video
        // once that's done notify of the result
    }
    
    // can only call if you have first attempted to post the video
    func retry() {
        writeFilteredVideoToFile()
    }
    // read each video frame, filter it, and then write it to an output file 
    // if that succeeds, attempt to upload it
    private func writeFilteredVideoToFile(){
        dispatch_async(dispatch_queue_create("movie_writer", DISPATCH_QUEUE_SERIAL)) {
            let asset = AVAsset(URL: self.sourceURL!)
            let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last
            if let (writer, pixelBufferAdaptor) = self.getWriterAndAdaptor(asset),
                let reader = self.getReader(asset) {
                if videoTrack != nil {
                    var isWriting = false
                    reader.startReading()
                    let readerOutput = reader.outputs.last!
                    while let buffer: CMSampleBuffer? = readerOutput.copyNextSampleBuffer() {
                        if buffer == nil {
                            break
                        }
                        var writingFirstFrame = false
                        autoreleasepool() {
                            if !isWriting {
                                if writer.startWriting() {
                                    writer.startSessionAtSourceTime(CMSampleBufferGetPresentationTimeStamp(buffer!))
                                    isWriting = true
                                    writingFirstFrame = true
                                } else {
                                    self.dispatchError()
                                    return
                                }
                            }
                            let pixelBuffer = CMSampleBufferGetImageBuffer(buffer!)
                            let image = FrameFilter.getProcessedImage(pixelBuffer!, filterSettings: self.filterSettings!)
                            if writingFirstFrame {
                                self.dispatchDidStart(image)
                                self.firstFrame = image
                            }
                            self.context.render(image, toCVPixelBuffer: pixelBuffer!)
                            while writer.inputs.last!.readyForMoreMediaData == false {
                                NSThread.sleepForTimeInterval(0.05)
                            }
                            let presentationTime = CMSampleBufferGetPresentationTimeStamp(buffer!)
                            pixelBufferAdaptor.appendPixelBuffer(pixelBuffer!, withPresentationTime: presentationTime)
                        }
                    }
                    writer.finishWritingWithCompletionHandler(){
                        print("Finished: \(Int(NSDate().timeIntervalSince1970))")
                        self.attemptUploadVideoAtURL(writer.outputURL)
                    }
                } else {
                    self.dispatchError()
                }
            }
        }
    }
    
    private func dispatchDidStart(firstFrame: CIImage) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.uploadDidStart(firstFrame)
        }
    }
    
    private func dispatchSuccess() {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.uploadDidSucceed()
        }
    }
    
    private func dispatchError(){
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.uploadDidError()
        }
    }
    
    private func attemptUploadVideoAtURL(sourceURL: NSURL) {
        if let session = AppDelegate.getAppDelegate().getSession() {
            getS3URLs(sourceURL, session: session)
        } else {
            AppDelegate.getAppDelegate().showError("Video Upload Error", message: "Please log out and log back in to upload a video")
            dispatchError()
        }
    }
    
    func getS3URLs(sourceURL: NSURL, session: String) {
        let parameters = [
            "session": session,
            "method": "GetVideoS3URL",
        ]
        print("getting s3 video url")
        Alamofire.request(.POST, "https://getkeyframe.com/api/gif",
            parameters: parameters)
            .responseJSON { response in
                API.processResponse(response, onSuccess: { value in
                    let json = JSON(value)
                    print(json)
                    if json["Success"].int == 1 {
                        let videoURL = json["Return", "VideoURL"].stringValue
                        let frameURL = json["Return", "FrameURL"].stringValue
                        let uuid = json["Return", "Uuid"].stringValue
                        self.uploadVideoToS3(sourceURL, s3URL: videoURL, frameURL: frameURL, uuid: uuid)
                    } else {
                        self.dispatchError()
                    }
                })
        }
    }
    
    private func uploadVideoToS3(sourceURL: NSURL, s3URL: String, frameURL: String, uuid: String) {
        print("Uploading video to s3")
        Alamofire.upload(.PUT, s3URL, file: sourceURL).progress { _, totalBytesRead, totalBytesExpectedToRead in
            print("bytes read: \(totalBytesRead)")
            }
            .response { request, response, data, error in
                // todo: error check
                self.uploadFirstFrameToS3(frameURL, uuid: uuid)
        }
    }
    
    private func uploadFirstFrameToS3(s3URL: String, uuid: String) {
        if firstFrame == nil {
            print("First frame == nil")
            return
        }
        print("uploading first frame to s3")
        let firstFrameCG = context.createCGImage(firstFrame!, fromRect: firstFrame!.extent)
        let firstFrameUI = UIImage(CGImage: firstFrameCG)
        let firstFrameData = UIImageJPEGRepresentation(firstFrameUI, 1.0)
        Alamofire.upload(.PUT, s3URL, data: firstFrameData!).progress { _, totalBytesRead, totalBytesExpectedToRead in
            print("bytes read: \(totalBytesRead)")
            }
            .response { request, response, data, error in
                // todo: error check
                self.reportUploadComplete(uuid)
        }

    }
    private func reportUploadComplete(uuid: String) {
        let session = AppDelegate.getAppDelegate().getSession()!
        let parameters = [
            "session": session,
            "method": "ReportUploadComplete",
            "uuid": uuid
        ]
        print("Reporting upload complete")
        Alamofire.request(.POST, "https://getkeyframe.com/api/gif",
            parameters: parameters)
            .responseJSON { response in
                API.processResponse(response, onSuccess: { value in
                    let json = JSON(value)
                    print(json)
                    if json["Success"].int == 1 {
                        self.dispatchSuccess()
                    } else {
                        self.dispatchError()
                    }
                })
        }
    }
//    private func uploadVideoAtURL(sourceURL: NSURL, session: String){
//        let headers = [
//            "Session": session,
//            "Format": "MOV"
//        ]
//        Alamofire.upload(.POST, "https://qa.yaychakula.com/api/gif/upload/", headers: headers, file: sourceURL).progress { _, totalBytesRead, totalBytesExpectedToRead in
////                self.updateUploadProgress(totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
//            }
//            .responseJSON { response in
//                API.processResponse(response, onSuccess: self.processUploadResponse, onFailure: {
//                    self.dispatchError()
//                })
//        }
//    }
    
    func processUploadResponse(value: AnyObject) {
        let json = JSON(value)
        if json["Success"].int == 1 {
            dispatchSuccess()
        } else {
            dispatchError()
        }
    }
    
    private func getReader(asset: AVAsset) -> AVAssetReader? {
        do {
            let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last
            let reader = try AVAssetReader(asset: asset)
            let readerOutputSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(unsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack!, outputSettings: readerOutputSettings)
            reader.addOutput(readerOutput)
            return reader
        } catch {
            return nil
        }
    }
    
    private func getWriterAndAdaptor(asset: AVAsset) -> (AVAssetWriter, AVAssetWriterInputPixelBufferAdaptor)? {
        let timeInterval = Int(NSDate().timeIntervalSince1970)
        let destURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "\(timeInterval).MOV")
        let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last
        do {
            let writer = try AVAssetWriter(URL: destURL, fileType: AVFileTypeQuickTimeMovie)
            let videoCompressionProps = [AVVideoAverageBitRateKey as String: videoTrack!.estimatedDataRate]
            let writerOutputSettings: [String: AnyObject] = [AVVideoCodecKey as String: AVVideoCodecH264,
                                                             AVVideoWidthKey as String: videoTrack!.naturalSize.width,
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