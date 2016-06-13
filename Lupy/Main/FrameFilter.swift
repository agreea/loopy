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
    case None, Chaplin, VHS, Vapor
}

class FrameFilter: NSObject {
    var filter = VideoFilter.None
    var luminosity = CGFloat(0.0)
    var vhsTrackingTextures = [CIImage]()
    private let offsets = [CGPoint(x: -1 * CGFloat(arc4random() % 3 + 3), y: CGFloat(arc4random() % 3 + 3)),
                           CGPoint(x: -1 * CGFloat(arc4random() % 3) - 3.0, y: CGFloat(arc4random() % 3) - 3.0),
                           CGPoint(x: -1 * CGFloat(arc4random() % 3) + 2.0, y: -1 * CGFloat(arc4random() % 3) - 4.0)]
//    private var cubeData: NSData
    private let colorCubeSize = 32
    override init(){
        if let path = NSBundle.mainBundle().pathForResource("Bad tracking_0", ofType: "jpg") {
            let url = NSURL(fileURLWithPath: path)
            if let textureImage = CIImage(contentsOfURL: url) {
                vhsTrackingTextures.append(textureImage)
            }
        }
//        cubeData = generateColorCube(colorCubeSize)
        super.init()
    }
    
    private func populateColorCube() {
    }
    
    private func getLuminousImage(image: CIImage) -> CIImage {
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
    
    private func getChaplinImage(image: CIImage) -> CIImage {
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
    
    // returns cached frame if possible
    // otherwise, renders the frame, caches it, and returns it
    
    private func getVHSImage(image: CIImage, frameIndex: Int) -> CIImage {
        
        let blurMaster = motionBlurImage(image, radius: 3.0)
        
        // create the alpha on the top
        let alphaMaster = alphaAdjust(blurMaster, alpha: 0.70)
        
        // drop the contrast for the top layer
        let contrastMaster = contrastAdjust(alphaMaster, contrast: 0.85)
        
        // unsharp from contrast, increasing difference between lights and darks
        let unsharpMaster = unsharpMask(contrastMaster, intensity: 0.8, radius: 5.0)
        
        // overlay master on top of channels
        let rgbClamp = getClampComposite(image, offsets: offsets)
        let overlayMaster = overlayImages(unsharpMaster, background: rgbClamp)

        var textureMaster = overlayMaster
        if let textureImage = getVHSTexture(frameIndex) {
            let hardLightParams = [
                kCIInputImageKey as String: overlayMaster,
                kCIInputBackgroundImageKey as String: textureImage
            ]
            textureMaster = CIFilter(name: "CIHardLightBlendMode", withInputParameters: hardLightParams)!.outputImage!
        }
        return textureMaster
    }
    
    private func overlayImages(image: CIImage, background: CIImage) -> CIImage {
        let overlayParams = [
            kCIInputImageKey as String: image,
            kCIInputBackgroundImageKey as String: background
        ]
        return CIFilter(name: "CISourceOverCompositing", withInputParameters: overlayParams)!.outputImage!
    }
    
    private func alphaAdjust(image: CIImage, alpha: CGFloat) -> CIImage {
        let alphaParams = [
            kCIInputImageKey as String: image,
            "inputAVector": CIVector(x: 0.0, y: 0.0, z: 0.0, w: alpha)
        ]
        return CIFilter(name: "CIColorMatrix", withInputParameters: alphaParams)!.outputImage!
    }
    
    private func contrastAdjust(image: CIImage, contrast: CGFloat) -> CIImage {
        let contrastParams = [
            kCIInputImageKey as String: image,
            "inputContrast": contrast,
            ]
        return CIFilter(name: "CIColorControls", withInputParameters: contrastParams)!.outputImage!
    }
    
    private func getVHSTexture(frameIndex: Int) -> CIImage? {
        let textureFrameIndex = frameIndex % 25
        if textureFrameIndex < vhsTrackingTextures.count {
//            let rotatedTexture = getRotatedImage(vhsTrackingTextures[textureFrameIndex])
//            return vhsTrackingTextures[textureFrameIndex]
            return getScaledImage(vhsTrackingTextures[textureFrameIndex], scaleX: 1.00, scaleY: (900.0/486.0))
        }
        return nil
    }
    
    private func unsharpMask(image: CIImage, intensity: CGFloat, radius: CGFloat) -> CIImage {
        let params = [
            kCIInputImageKey as String: image,
            kCIInputIntensityKey as String: intensity,
            kCIInputRadiusKey as String: radius
        ]
        return CIFilter(name: "CIUnsharpMask", withInputParameters: params)!.outputImage!
    }
    
    private func motionBlurImage(image: CIImage, radius: CGFloat) -> CIImage {
        let blurParams = [
            kCIInputImageKey as String: image,
            kCIInputRadiusKey as String: radius
        ]
        return CIFilter(name: "CIMotionBlur", withInputParameters: blurParams)!.outputImage!
    }
    
    private func getClampComposite(image: CIImage, offsets: [CGPoint]) -> CIImage {
        let rClamp = getRClampImage(image)
        let bClamp = getBClampImage(image)
        let gClamp = getGClampImage(image)
        let rbExclusion = getClampExclusion(rClamp, backgroundImage: bClamp, offsets: [offsets[0], offsets[1]])
        return getClampExclusion(rbExclusion, backgroundImage: gClamp, offsets: [offsets[1], offsets[2]])
    }
    
    private func getClampExclusion(image: CIImage, backgroundImage: CIImage, offsets: [CGPoint]) -> CIImage {
        let firstTranslateImage = getTranslatedImage(image, offset: offsets[0])
        let secondTranslateImage = getTranslatedImage(backgroundImage, offset: offsets[1])
        let rbgParams = [
            kCIInputImageKey as String: firstTranslateImage,
            kCIInputBackgroundImageKey as String: secondTranslateImage
        ]
        return CIFilter(name: "CIExclusionBlendMode", withInputParameters: rbgParams)!.outputImage!
    }
    
    private func getTranslatedImage(image: CIImage, offset: CGPoint) -> CIImage {
        let params = [
            kCIInputImageKey as String: image
        ]
        let translate = CIFilter(name: "CIAffineTransform", withInputParameters: params)
        let transform = CGAffineTransformMakeTranslation(offset.x, offset.y)
        translate!.setValue(NSValue(CGAffineTransform: transform), forKey: "inputTransform")
        return translate!.outputImage!
    }
    
    private func getScaledImage(image: CIImage, scaleX: CGFloat, scaleY: CGFloat) -> CIImage {
        let params = [
            kCIInputImageKey as String: image
        ]
        let translate = CIFilter(name: "CIAffineTransform", withInputParameters: params)
        let transform = CGAffineTransformMakeScale(scaleX, scaleY)
        translate!.setValue(NSValue(CGAffineTransform: transform), forKey: "inputTransform")
        return translate!.outputImage!
    }
    
    private func getRotatedImage(image: CIImage) -> CIImage {
        let params = [
            kCIInputImageKey as String: image
        ]
        let translate = CIFilter(name: "CIAffineTransform", withInputParameters: params)
        let transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90.0))
        translate!.setValue(NSValue(CGAffineTransform: transform), forKey: "inputTransform")
        return translate!.outputImage!
    }
    
    private func getRClampImage(image: CIImage) -> CIImage {
        let vector = CIVector(x: 0.0, y: 1.0, z: 1.0, w: 1.0)
//        let blurImage = motionBlurImage(image, radius: 55.0)
        return getClampImage(image, vector: vector)
    }
    
    private func getBClampImage(image: CIImage) -> CIImage {
        let vector = CIVector(x: 1.0, y: 1.0, z: 0.0, w: 1.0)
//        let blurImage = motionBlurImage(image, radius: 55.0)
        return getClampImage(image, vector: vector)
    }
    
    private func getGClampImage(image: CIImage) -> CIImage {
        let vector = CIVector(x: 1.0, y: 0.0, z: 1.0, w: 1.0)
//        let blurImage = motionBlurImage(image, radius: 55.0)
        return getClampImage(image, vector: vector)
    }
    
    private func getClampImage(image: CIImage, vector: CIVector) -> CIImage {
        let params = [
            kCIInputImageKey: image,
            "inputMaxComponents": vector
            ]
        return CIFilter(name: "CIColorClamp", withInputParameters: params)!.outputImage!
    }
    
//    private func getYellowsMask(image: CIImage) -> CIImage {
//        let params = [
//            kCIInputImageKey: image,
//            "inputCubeDimension": colorCubeSize,
//            "inputCubeData": cubeData
//        ]
//        return CIFilter(name: "CIColorCube", withInputParameters: params)!.outputImage!
//    }
    
    private func getVaporImage(image: CIImage) -> CIImage {
        // prepare the yellows
//        let yellowMask = getYellowsMask(image)
//        let rVector = CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0)
//        let gVector = CIVector(x: 0.0, y: 1.48, z: -0.47, w: 0.0)
//        let bVector = CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0)
//        let aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
//        let vectors = [rVector, gVector, bVector, aVector]
//        let yellowAmp = matrixAdjust(yellowMask, matrix: vectors)
//        let yellowComposite = overlayImages(yellowAmp, background: image)
        let params = [
            kCIInputImageKey: hueAdjust(image, degrees: -35.0),
        ]
        return CIFilter(name: "CIPhotoEffectChrome", withInputParameters: params)!.outputImage!
//        return matrixAdjust(image, matrix: vectors)
    }
    
    // matrix must have count == 4
    private func matrixAdjust(image: CIImage, matrix: [CIVector]) -> CIImage {
        let params = [
            kCIInputImageKey: image,
            "inputRVector": matrix[0],
            "inputGVector": matrix[1],
            "inputBVector": matrix[2],
            "inputAVector": matrix[3]
        ]
        return CIFilter(name: "CIColorMatrix", withInputParameters: params)!.outputImage!
    }
    
    private func hueAdjust(image: CIImage, degrees: Double) -> CIImage {
        let params = [
            kCIInputImageKey: image,
            kCIInputAngleKey: degrees * M_PI / 180
        ]
        return CIFilter(name: "CIHueAdjust", withInputParameters: params)!.outputImage!
    }
    static func getProcessedImage(imageBuffer: CVPixelBuffer) {
        //       let gpuImagePic = GPUImagePicture(
//        let stillImageFilter2 = GPUImageSepiaFilter()
        
        //        stillImageFilter2.image
    }
    
    func getProcessedImageFromBuffer(imageBuffer: CVPixelBuffer, frameIndex: Int) -> CIImage {
        let ciImage = CIImage(CVPixelBuffer: imageBuffer)
        return getProcessedImage(ciImage, frameIndex: frameIndex)
    }
    
    func getProcessedImage(image: CIImage, frameIndex: Int) -> CIImage {
        let luminousImage = getLuminousImage(image)
        return getImageWithFilter(luminousImage, frameIndex: frameIndex)
    }
    
    func getProcessedImageWithFilter(image: CIImage, filter: VideoFilter) -> CIImage {
        var imagePreCropped = image
        switch filter {
        case .Chaplin:
            imagePreCropped = getChaplinImage(image)
            break
        case .VHS:
            imagePreCropped = getVHSImage(image, frameIndex: 0)
            break
        case .Vapor:
            imagePreCropped = getVaporImage(image)
            break
        default:
            break
        }
        return getScaleCroppedImage(imagePreCropped)
    }
    
    private func getScaleCroppedImage(image: CIImage) -> CIImage {
        let scalar = 740.0 / 720.0
        let originX = 720.0 * (scalar - 1) / 2
        let originY = 900.0 * (scalar - 1) / 2
        let endX = 720.0 * scalar - originX
        let endY = 900.0 * scalar - originY
        let scalarFloat = CGFloat(scalar)
        let scaledImage = getScaledImage(image, scaleX: scalarFloat, scaleY: scalarFloat)
        let params = [
            kCIInputImageKey: scaledImage,
            "inputRectangle": CIVector(x: CGFloat(originX), y: CGFloat(originY), z: CGFloat(endX), w: CGFloat(endY))
        ]
        let cropped = CIFilter(name: "CICrop", withInputParameters: params)
        return getTranslatedImage(cropped!.outputImage!, offset: CGPoint(x: -originX, y: -originY))
//        return cropped!.outputImage!
    }
    
    private func populateVHSTextures() {
        for i in 1...25 {
            if let path = NSBundle.mainBundle().pathForResource("Bad tracking_\(i * 2)", ofType: "jpg") {
                print(path)
                let url = NSURL(fileURLWithPath: path)
                if let textureImage = CIImage(contentsOfURL: url) {
                    vhsTrackingTextures.append(textureImage)
                }
            }
        }
    }
    
    // should only be passed a luminous image
    private func getImageWithFilter(image: CIImage, frameIndex: Int) -> CIImage {
        var imagePreCropped = image
        switch filter {
        case .Chaplin:
            imagePreCropped = getChaplinImage(image)
            break
        case .VHS:
            if vhsTrackingTextures.count <= 1 {
                populateVHSTextures()
            }
            imagePreCropped = getVHSImage(image, frameIndex: frameIndex)
            break
        case .Vapor:
            imagePreCropped = getVaporImage(image)
            break
        default:
            break
        }
        return getScaleCroppedImage(imagePreCropped)
    }
}

func generateColorCube(size: Int) -> NSData {
    let cubeDataSize = size * size * size * sizeof (Float) * 4
    let cubeData = UnsafeMutablePointer<Float>.alloc(cubeDataSize)
    var rgb = [Float(0), Float(0), Float(0)]
    var offset: size_t = 0
    for b in 0...size-1 {
        rgb[2] = Float(b) / Float(size) // blue value
        for g in 0...size-1 {
            rgb[1] = Float(g) / Float(size-1) // green value
            for r in 0...size-1 {
                rgb[0] = Float(r) / Float(size-1) // red value
                let (h, s, v) = RGBtoHSV(CGFloat(rgb[0]), g: CGFloat(rgb[1]), b: CGFloat(rgb[2]))
                let h_radians = h * 2.0 * CGFloat(M_PI)
                let minYellow = CGFloat(0.08)
                let maxYellow = CGFloat(0.22)
                if h > minYellow && h < maxYellow {
                    cubeData[offset]   = rgb[0]
                    cubeData[offset+1] = rgb[1]
                    cubeData[offset+2] = rgb[2]
                } else {
                    let shiftHue_radians = h_radians > DEGREES_TO_RADIANS(35.0) ? h_radians - DEGREES_TO_RADIANS(35.0) : 1 + h_radians - DEGREES_TO_RADIANS(35.0)
                    let shiftHue = shiftHue_radians / (2.0 * CGFloat(M_PI))
                    let shiftedColor =  UIColor(hue: shiftHue, saturation: s, brightness: v, alpha: 1.0)
                    var cgR = CGFloat(0.0)
                    var cgG = CGFloat(0.0)
                    var cgB = CGFloat(0.0)
                    var cgA = CGFloat(0.0)
                    shiftedColor.getRed(&cgR, green: &cgG, blue: &cgB, alpha: &cgA)
                    cubeData[offset]   = Float(cgR)
                    cubeData[offset+1] = Float(cgG)
                    cubeData[offset+2] = Float(cgB)
                }
                cubeData[offset+3] = Float(1.0)
                offset += 4
            }
        }
    }
    return NSData(bytesNoCopy: cubeData, length: cubeDataSize, freeWhenDone: true)
}

func RGBtoHSV(r: CGFloat, g: CGFloat, b: CGFloat) -> (h: CGFloat, s: CGFloat, v: CGFloat) {
    var h : CGFloat = 0.0
    var s : CGFloat = 0.0
    var v : CGFloat = 0.0
    let col = UIColor(red: r, green: g, blue: b, alpha: 1.0)
    col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
    return (h, s, v)
}