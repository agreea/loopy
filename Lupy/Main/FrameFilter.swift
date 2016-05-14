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
import GPUImage
import CoreGraphics

enum VideoFilter {
    case None, Chaplin, Clamp
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
            "inputContrast": CGFloat(1.0),
            "inputSaturation": CGFloat(0.0)
        ]
        let blackAndWhite = CIFilter(name: "CIColorControls", withInputParameters: bwParams)!.outputImage!
        let exposureAdjustParams = [
            kCIInputImageKey as String: blackAndWhite,
            "inputEV": 0.7
        ]
        return CIFilter(name: "CIExposureAdjust", withInputParameters: exposureAdjustParams)!.outputImage!
    }
    
    private static func getVHSImage(image: CIImage, offsets: [CGPoint], frameIndex: Int) -> CIImage {
        let blurMaster = motionBlurImage(image, radius: 3.0)
        // create alpha
        let alphaMaster = alphaAdjust(blurMaster, alpha: 0.70)
        
        // contrast from alpha
        let contrastMaster = contrastAdjust(alphaMaster, contrast: 0.92)
        
        // unsharp from contrast
        let unsharpMaster = unsharpMask(contrastMaster, intensity: 0.8, radius: 5.0)
        
        // overlay master with texture
        var textureMaster = unsharpMaster
        if let textureImage = getVHSTexture(frameIndex) {
            let hardLightParams = [
                kCIInputImageKey as String: textureImage,
                kCIInputBackgroundImageKey as String: unsharpMaster
            ]
            textureMaster = CIFilter(name: "CISoftLightBlendMode", withInputParameters: hardLightParams)!.outputImage!
        }
        
        let rgbClamp = getClampComposite(image, offsets: offsets)
        let textureMasterClampOverlay = overlayImages(textureMaster, background: rgbClamp)
        return textureMasterClampOverlay
    }
    
    private static func overlayImages(image: CIImage, background: CIImage) -> CIImage {
        let overlayParams = [
            kCIInputImageKey as String: image,
            kCIInputBackgroundImageKey as String: background
        ]
        return CIFilter(name: "CISourceOverCompositing", withInputParameters: overlayParams)!.outputImage!
    }
    
    private static func alphaAdjust(image: CIImage, alpha: CGFloat) -> CIImage {
        let alphaParams = [
            kCIInputImageKey as String: image,
            "inputAVector": CIVector(x: 0.0, y: 0.0, z: 0.0, w: alpha)
        ]
        return CIFilter(name: "CIColorMatrix", withInputParameters: alphaParams)!.outputImage!
    }
    
    private static func contrastAdjust(image: CIImage, contrast: CGFloat) -> CIImage {
        let contrastParams = [
            kCIInputImageKey as String: image,
            "inputContrast": contrast,
            ]
        return CIFilter(name: "CIColorControls", withInputParameters: contrastParams)!.outputImage!
    }
    
    private static func getVHSTexture(frameIndex: Int) -> CIImage? {
        let textureFrameIndex = frameIndex % 59
        if let path = NSBundle.mainBundle().pathForResource("blankTape_\(textureFrameIndex)", ofType: "jpg") {
            print(path)
            let url = NSURL(fileURLWithPath: path)
            if let textureImage = CIImage(contentsOfURL: url) {
                let textureContrast = contrastAdjust(textureImage, contrast: 1.8)
                let textureAlpha = alphaAdjust(textureContrast, alpha: 0.04)
                return textureAlpha
            }
        }
        print("no texture")
        return nil
    }
    
    private static func unsharpMask(image: CIImage, intensity: CGFloat, radius: CGFloat) -> CIImage {
        let params = [
            kCIInputImageKey as String: image,
            kCIInputIntensityKey as String: intensity,
            kCIInputRadiusKey as String: radius
        ]
        return CIFilter(name: "CIUnsharpMask", withInputParameters: params)!.outputImage!
    }
    
    private static func motionBlurImage(image: CIImage, radius: CGFloat) -> CIImage {
        let blurParams = [
            kCIInputImageKey as String: image,
            kCIInputRadiusKey as String: radius
        ]
        return CIFilter(name: "CIMotionBlur", withInputParameters: blurParams)!.outputImage!
    }
    
    private static func getClampComposite(image: CIImage, offsets: [CGPoint]) -> CIImage {
        let rClamp = getRClampImage(image)
        let bClamp = getBClampImage(image)
        let gClamp = getGClampImage(image)
        let rbExclusion = getClampExclusion(rClamp, backgroundImage: bClamp, offsets: [offsets[0], offsets[1]])
        return getClampExclusion(rbExclusion, backgroundImage: gClamp, offsets: [offsets[1], offsets[2]])
//        let rbExclusionFilter = CIFilter(name: "CIExclusionBlendMode", withInputParameters: rbParams)!
//        let rbExclusion = CIFilter(name: "CIExclusionBlendMode", withInputParameters: rbParams)!.outputImage!
//        let rbgParams = [
//            kCIInputImageKey as String: rbExclusion,
//            kCIInputBackgroundImageKey as String: gClamp
//        ]
//        let rgbExclusion = CIFilter(name: "CIExclusionBlendMode", withInputParameters: rbgParams)!.outputImage!
//        return rgbExclusion
    }
    
    private static func getClampExclusion(image: CIImage, backgroundImage: CIImage, offsets: [CGPoint]) -> CIImage {
        let firstTranslateImage = getTranslatedImage(image, offset: offsets[0])
        let secondTranslateImage = getTranslatedImage(backgroundImage, offset: offsets[1])
        let rbgParams = [
            kCIInputImageKey as String: firstTranslateImage,
            kCIInputBackgroundImageKey as String: secondTranslateImage
        ]
        return CIFilter(name: "CIExclusionBlendMode", withInputParameters: rbgParams)!.outputImage!
    }
    
    private static func getTranslatedImage(image: CIImage, offset: CGPoint) -> CIImage {
        let params = [
            kCIInputImageKey as String: image
        ]
        let translate = CIFilter(name: "CIAffineTransform", withInputParameters: params)
        let transform = CGAffineTransformMakeTranslation(offset.x, offset.y)
        translate!.setValue(NSValue(CGAffineTransform: transform), forKey: "inputTransform")
        return translate!.outputImage!
    }
    
    private static func getRClampImage(image: CIImage) -> CIImage {
        let vector = CIVector(x: 0.0, y: 1.0, z: 1.0, w: 1.0)
//        let blurImage = motionBlurImage(image, radius: 55.0)
        return getClampImage(image, vector: vector)
    }
    
    private static func getBClampImage(image: CIImage) -> CIImage {
        let vector = CIVector(x: 1.0, y: 1.0, z: 0.0, w: 1.0)
//        let blurImage = motionBlurImage(image, radius: 55.0)
        return getClampImage(image, vector: vector)
    }
    
    private static func getGClampImage(image: CIImage) -> CIImage {
        let vector = CIVector(x: 1.0, y: 0.0, z: 1.0, w: 1.0)
//        let blurImage = motionBlurImage(image, radius: 55.0)
        return getClampImage(image, vector: vector)
    }
    
    private static func getClampImage(image: CIImage, vector: CIVector) -> CIImage {
        let params = [
            kCIInputImageKey as String: image,
            "inputMaxComponents": vector,
            ]
        return CIFilter(name: "CIColorClamp", withInputParameters: params)!.outputImage!
    }
    
    static func getProcessedImage(imageBuffer: CVPixelBuffer) {
        //       let gpuImagePic = GPUImagePicture(
//        let stillImageFilter2 = GPUImageSepiaFilter()
        
        //        stillImageFilter2.image
    }
    static func getProcessedImage(imageBuffer: CVPixelBuffer, filterSettings: FilterSettings, frameIndex: Int, offsets: [CGPoint]) -> CIImage {
        let ciImage = CIImage(CVPixelBuffer: imageBuffer)
        let luminousImage = FrameFilter.getLuminousImage(ciImage, luminosity: filterSettings.luminosity)
        return getImageWithFilter(luminousImage, filter: filterSettings.filter, frameIndex: frameIndex, offsets: offsets)
    }
    
    static func getProcessedImage(image: CIImage, filterSettings: FilterSettings, frameIndex: Int, offsets: [CGPoint]) -> CIImage {
        let luminousImage = FrameFilter.getLuminousImage(image, luminosity: filterSettings.luminosity)
        return getImageWithFilter(luminousImage, filter: filterSettings.filter, frameIndex: frameIndex, offsets: offsets)
    }

    // should only be passed a luminous image
    private static func getImageWithFilter(image: CIImage, filter: VideoFilter, frameIndex: Int, offsets: [CGPoint]) -> CIImage {
        switch filter {
        case .Chaplin:
            return getChaplinImage(image)
        case .Clamp:
            return getVHSImage(image, offsets: offsets, frameIndex: frameIndex)
        default:
            return image
        }
    }
}