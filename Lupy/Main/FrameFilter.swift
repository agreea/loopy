//
//  FrameFilter.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/27/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import AVFoundation
import GLKit

enum VideoFilter {
    case None, Chaplin
}

struct FilterSettings {
    var luminosity: CGFloat
    var filter: VideoFilter
}

class FrameFilter {
    
    private static func getLuminousImage(image: CIImage, luminosity: CGFloat) -> CIImage {
        if luminosity == 0 {
            return image
        }
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
    
    private static func getChaplinImage(image: CIImage) -> CIImage {
        let bwParams = [
            kCIInputImageKey as String: image,
            "inputBrightness": CGFloat(0.0),
            "inputContrast": CGFloat(1.1),
            "inputSaturation": CGFloat(0.0)
        ]
        let blackAndWhite = CIFilter(name: "CIColorControls", withInputParameters: bwParams)!.outputImage!
//        CIImage *blackAndWhite = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, beginImage, @"inputBrightness", [NSNumber numberWithFloat:0.0], @"inputContrast", [NSNumber numberWithFloat:1.1], @"inputSaturation", [NSNumber numberWithFloat:0.0], nil].outputImage;
        let exposureAdjustParams = [
            kCIInputImageKey as String: blackAndWhite,
            "inputEV": 0.7
        ]
        return CIFilter(name: "CIExposureAdjust", withInputParameters: exposureAdjustParams)!.outputImage!
    }
    
    static func getProcessedImage(imageBuffer: CVPixelBuffer, filterSettings: FilterSettings) -> CIImage {
        let ciImage = CIImage(CVPixelBuffer: imageBuffer)
        let luminousImage = FrameFilter.getLuminousImage(ciImage, luminosity: filterSettings.luminosity)
        return getImageWithFilter(luminousImage, filter: filterSettings.filter)
    }
    
    static func getProcessedImage(image: CIImage, filterSettings: FilterSettings) -> CIImage {
        let luminousImage = FrameFilter.getLuminousImage(image, luminosity: filterSettings.luminosity)
        return getImageWithFilter(luminousImage, filter: filterSettings.filter)
    }

    // should only be passed a luminous image
    private static func getImageWithFilter(image: CIImage, filter: VideoFilter) -> CIImage {
        switch filter {
        case .Chaplin:
            return getChaplinImage(image)
        default:
            return image
        }
    }
}