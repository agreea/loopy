//
//  VideoBufferManager.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/24/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation
import CoreGraphics
import UIKit
// a class that takes sample buffers and writes/stores them asynchronously

private enum MovieRecorderStatus: Int {
    case Idle = 0
    case PreparingToRecord
    case Recording
    // waiting for inflight buffers to be appended
    case FinishingRecordingPart1
    // calling finish writing on the asset writer
    case FinishingRecordingPart2
    // terminal state
    case Finished
    // terminal state
    case Failed
}   // internal state machine

#if LOG_STATUS_TRANSITIONS
    extension MovieRecorderStatus: CustomStringConvertible {
        var description: String {
            switch self {
            case .Idle:
                return "Idle"
            case .PreparingToRecord:
                return "PreparingToRecord"
            case .Recording:
                return "Recording"
            case .FinishingRecordingPart1:
                return "FinishingRecordingPart1"
            case .FinishingRecordingPart2:
                return "FinishingRecordingPart2"
            case .Finished:
                return "Finished"
            case .Failed:
                return "Failed"
            }
        }
    }
#endif


class VideoBufferManager: NSObject {
    var imageBuffers: [CVImageBuffer]
    private var _status: MovieRecorderStatus = .Idle
    private var _writingQueue: dispatch_queue_t
    private var _readingQueue: dispatch_queue_t
    override init() {
        _writingQueue = dispatch_queue_create("movie_writer", DISPATCH_QUEUE_SERIAL)
        imageBuffers = [CVImageBuffer]()
        _readingQueue = dispatch_queue_create("movie_reader", DISPATCH_QUEUE_SERIAL)
        super.init()
    }
    
    func recordSampleBuffer(sampleBuffer: CMSampleBuffer) {
        // write async
//        synced(self) {
//            if self._status.rawValue < MovieRecorderStatus.Recording.rawValue {
//                fatalError("Not ready to record yet")
//            }
//        }
        
        dispatch_async(_writingQueue) {
            autoreleasepool {
//                self.synced(self) {
//                    if self._status.rawValue > MovieRecorderStatus.FinishingRecordingPart1.rawValue {
//                        return
//                    }
//                }
                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                self.imageBuffers.append(pixelBuffer!)
                print("Images ct: \(self.imageBuffers.count)")
            }
        }
    }
    
    func extractFramesFromVideoAtURL(movieURL: NSURL, completion: (UIImage, CMTime) -> Void) {
        dispatch_async(_readingQueue) {
            let asset = AVAsset(URL: movieURL)
            do {
                let assetReader = try AVAssetReader(asset: asset)
                if let videoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).last {
                    var outputSettings = [String : AnyObject]()
                    outputSettings[kCVPixelBufferPixelFormatTypeKey as String] = NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                    let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
                    assetReader.addOutput(output)
                    assetReader.startReading()
                    var samples = [CMSampleBuffer]()
                    while let sample = output.copyNextSampleBuffer() {
                        samples.append(sample)
                    }
                    let images = self.extractImagesFromSamples(samples)
                    print("Images count: \(images.count)")
                    print("Duration in seconds: \(asset.duration.seconds)")
                    let animatedImage = UIImage.animatedImageWithImages(images, duration: asset.duration.seconds)
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(animatedImage!, asset.duration)
                    }
                }
            } catch {
                print("AV Asset reader failed to read...")
            }
        }
    }
    
    private func extractImagesFromSamples(samples: [CMSampleBuffer]) -> [UIImage] {
        var images = [UIImage]()
        var lastImage: UIImage?
        for sampleBuffer in samples {
            let cgImage = convertBufferToImage(sampleBuffer)
            let uiImage = UIImage(CIImage: cgImage)
            images.append(uiImage)
            if lastImage != nil {
                print("Are adjacent images equal: \(areImagesEqual(lastImage!, second: uiImage))")
            }
            lastImage = uiImage
        }
        return images
    }
    
    private func areImagesEqual(first: UIImage, second: UIImage) -> Bool {
        let data1 = UIImagePNGRepresentation(first)
        let data2 = UIImagePNGRepresentation(second)
        if data1 == nil && data2 == nil {
            print("Both img nil")
        }
        return data1!.isEqualToData(data2!)
    }

    private func convertBufferToImage(sampleBuffer: CMSampleBuffer) -> CIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciImage = CIImage(CVImageBuffer: imageBuffer)
        return ciImage
        /* CVBufferRelease(imageBuffer); */  // do not call this!
    }
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }

    
    // write assets to file
    // write buffer to image
    // write buffer to pixelbuffer
    // serve images
    //
}
