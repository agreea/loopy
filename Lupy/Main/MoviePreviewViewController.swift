//
//  MoviePreviewView.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/3/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Alamofire
import SwiftyJSON
import CoreData

enum InterfaceToggle {
    case Filter, Brightness
}
struct FilterPreview {
    let name: String
    let filter: VideoFilter
    var selected: Bool
}

class MoviePreviewViewController: UIViewController {
    var moviePlayer: AVPlayerViewController!
    var player: AVPlayer?
    var images: [UIImage]?
    var coreImageView: CoreImageView?
    var uploadedBytesRepresented: Int64?
    var movieURL: NSURL?
    var firstFrame: CIImage?
    var filterPreviews = [FilterPreview(name: "Natural", filter: .None, selected: true),
                          FilterPreview(name: "Chaplin", filter: .Chaplin, selected: false),
                          FilterPreview(name: "Clamp", filter: .Clamp, selected: false)]
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var moviePreview: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var filterView: UICollectionView!
    @IBOutlet weak var loadingVideoLabel: UILabel!
    
    
    private var interfaceToggle = InterfaceToggle.Filter
    var interfaceState: InterfaceToggle {
        get {
            return interfaceToggle
        }
        set(newValue){
            interfaceToggle = newValue
            updateBottomInterface()
        }
    }
    var captureModeDelegate: CaptureModeDelegate?
    var videoSource: VideoSampleBufferSource?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let filterNib = UINib(nibName: "FilterViewCell", bundle: nil)
        filterView.registerNib(filterNib, forCellWithReuseIdentifier: "filterCell")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let frame = bottomView.frame
        let previewWindowHeight = self.view.bounds.width * 1.25
        let bottomViewHeight = self.view.bounds.height - previewWindowHeight
        bottomView.frame = CGRect(x: 0,
                                  y: previewWindowHeight,
                                  width: frame.width,
                                  height: bottomViewHeight)
        bottomView.setNeedsLayout()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        coreImageView = nil
        print("You bet view did disappear")
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func previewModeDidStart() {
        // get the movieFile from a player
        // loop the video
//        let playerItem = AVPlayerItem(URL: movieURL!)
//        let movie = GPUImageMovie(URL: movieURL!)
//        let player = AVPlayer(playerItem: playerItem)
//        player.rate = 1.0
//        movie.shouldRepeat = true
//        movie.playAtActualSpeed = true
//        let gpuImageView = GPUImageView(frame: moviePreview.bounds)
////        let filter = GPUImageBoxBlurFilter()
//        movie.addTarget(gpuImageView)
////        filter.addTarget(gpuImageView)
//        moviePreview.insertSubview(gpuImageView, atIndex: 0)
//        movie.startProcessing()
//        print("Gpu imageview frame: \(gpuImageView.frame)")
        loadingVideoLabel.hidden = true
//        player.play()
        videoSource?.stop()
        loadingVideoLabel.hidden = true
        if coreImageView == nil {
            print("Adding core image view")
            coreImageView = CoreImageView(frame: moviePreview.bounds)
            moviePreview.insertSubview(coreImageView!, atIndex: 0)
        }
        videoSource = VideoSampleBufferSource() { [unowned self] image in
            self.handleVideoFrame(image)
        }
        videoSource!.start(movieURL!)
    }
    
    func handleVideoFrame(image: CIImage) {
        // get transformation for this rotation
//        let rotateTransform = image.imageTransformForOrientation(Int32(6))
//        coreImageView!.image = image.imageByApplyingTransform(rotateTransform)
        coreImageView!.image = image
        if firstFrame == nil {
            firstFrame = coreImageView!.image
            populateFilterCells()
        }
        if coreImageView!.hidden {
            self.coreImageView!.hidden = false
        }
    }
    
    func populateFilterCells(){
        filterView.dataSource = self
        filterView.delegate = self
        filterView.reloadData()
        filterView.hidden = false
    }
    
//    func initPlayer() {
//        if player == nil {
//            player = AVPlayer(URL: movieURL!)
//        } else {
//            let playerItem = AVPlayerItem(URL: movieURL!)
//            player?.replaceCurrentItemWithPlayerItem(playerItem)
//        }
//        player!.actionAtItemEnd = .None
//        //set a listener for when the video ends
//        NSNotificationCenter
//            .defaultCenter()
//            .addObserver(self,
//                         selector: #selector(MoviePreviewViewController.restartVideoFromBeginning),
//                         name: AVPlayerItemDidPlayToEndTimeNotification,
//                         object: player!.currentItem)
//        let playerLayer = AVPlayerLayer(player: player)
//        playerLayer.frame = self.view.bounds
//        let moviePreviewView = UIView(frame: self.view.bounds)
//        moviePreviewView.layer.addSublayer(playerLayer)
//        self.view.insertSubview(moviePreviewView, atIndex: 0)
//        print("sublayer added")
//        player!.play()
//    }
//    

    
    @IBAction func didPressCancel(sender: AnyObject) {
        // go back to the captureView
        captureModeDelegate!.captureModeDidStart()
        prepareForDisappear()
    }
    
    @IBAction func didPressSend(sender: AnyObject) {
        print("Writing file START: \(Int(NSDate().timeIntervalSince1970))")
        videoSource!.stop()
        captureModeDelegate?.didPressUpload(movieURL!, filterSettings: videoSource!.filterSettings)
        prepareForDisappear()
    }
    
    private func prepareForDisappear() {
        videoSource?.stop()
        videoSource = nil
        slider.value = 0.5
        firstFrame = nil
        loadingVideoLabel.hidden = false
        interfaceState = .Filter
        filterView.hidden = true
        for i in 0...filterPreviews.count-1 {
            filterPreviews[i].selected = false
        }
        filterPreviews[0].selected = true
        if coreImageView != nil {
            coreImageView!.image = nil
            coreImageView!.hidden = true
            coreImageView!.removeFromSuperview()
            coreImageView = nil
        } else {
            print("core image view was nil")
        }
    }
    
    @IBAction func sliderDidSlide(sender: UISlider) {
        print(sender.value)
        videoSource!.setLuminosity(sender.value)
    }
    
    @IBAction func didPressFilter(sender: AnyObject) {
        interfaceState = .Filter
    }
    
    @IBAction func didPressBrightness(sender: AnyObject) {
        interfaceState = .Brightness
    }

    private func updateBottomInterface() {
        if interfaceState == .Filter {
            label.text = "Filter"
            slider.hidden = true
            filterView.hidden = false
        } else {
            label.text = "Brightness"
            filterView.hidden = true
            slider.hidden = false
        }
    }
}

extension MoviePreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return filterPreviews.count
    }
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("filterCell", forIndexPath: indexPath) as! FilterViewCell
        let index = indexPath.row
        let filterPreview = filterPreviews[index]
        let image = videoSource!.getProcessedImage(firstFrame!, filter: filterPreview.filter)
        cell.loadCell(image, name: filterPreview.name, selected: filterPreview.selected)
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        for i in 0...(filterPreviews.count-1) {
            if i == indexPath.row {
                filterPreviews[i].selected = true
                videoSource!.filter = filterPreviews[i].filter
            } else {
                filterPreviews[i].selected = false
            }
        }
        filterView.reloadData()
    }
//    -(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
//    
//    UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
//    datasetCell.backgroundColor = [UIColor blueColor]; // highlight selection
//    }
//    
//    -(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
//    
//    UICollectionViewCell *datasetCell =[collectionView cellForItemAtIndexPath:indexPath];
//    datasetCell.backgroundColor = [UIColor redColor]; // Default color
//    }

    
}
typealias Filter = CIImage -> CIImage

func blur(radius: Double) -> Filter {
    return { image in
        let parameters = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIGaussianBlur",
                              withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func colorGenerator(color: UIColor) -> Filter {
    return { _ in
        let parameters = [kCIInputColorKey: color]
        let filter = CIFilter(name: "CIConstantColorGenerator",
                              withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func hueAdjust(angleInRadians: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputAngleKey: angleInRadians,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIHueAdjust",
                              withInputParameters: parameters)
        return filter!.outputImage!
        
    }
}

func pixellate(scale: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            kCIInputScaleKey:scale
        ]
        return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
    }
}

func kaleidoscope() -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            ]
        return CIFilter(name: "CITriangleKaleidoscope", withInputParameters: parameters)!.outputImage!.imageByCroppingToRect(image.extent)
    }
}


func vibrance(amount: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey: image,
            "inputAmount": amount
        ]
        return CIFilter(name: "CIVibrance", withInputParameters: parameters)!.outputImage!
    }
}

func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        let filter = CIFilter(name: "CISourceOverCompositing",
                              withInputParameters: parameters)
        let cropRect = image.extent
        return filter!.outputImage!.imageByCroppingToRect(cropRect)
    }
}


func radialGradient(center: CGPoint, radius: CGFloat) -> CIImage {
    let params: [String: AnyObject] = [
        "inputColor0": CIColor(red: 1, green: 1, blue: 1),
        "inputColor1": CIColor(red: 0, green: 0, blue: 0),
        "inputCenter": CIVector(CGPoint: center),
        "inputRadius0": radius,
        "inputRadius1": radius + 1
    ]
    return CIFilter(name: "CIRadialGradient", withInputParameters: params)!.outputImage!
}

func blendWithMask(background: CIImage, mask: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: mask,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIBlendWithMask",
                              withInputParameters: parameters)
        let cropRect = image.extent
        return filter!.outputImage!.imageByCroppingToRect(cropRect)
    }
}

func colorOverlay(color: UIColor) -> Filter {
    return { image in
        let overlay = colorGenerator(color)(image)
        return compositeSourceOver(overlay)(image)
    }
}


infix operator >>> { associativity left }

func >>> (filter1: Filter, filter2: Filter) -> Filter {
    return { img in filter2(filter1(img)) }
}
