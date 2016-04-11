//
//  CaptureView.swift
//  Loopy
//
//  Created by Agree Ahmed on 3/21/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import AVFoundation
import Proposer

protocol CaptureModeDelegate {
    func previewModeDidStart(movieURL: NSURL)
    func captureModeDidStart()
    // if I'm about to go into preview mode, cut the size of the frame in half
    // if I'm about to go into capture mode, double the size of the frame
    // notify you when the view is about to go into preview mode
    // notify you when it's about to exit preview mode
}

class CaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    var captureSession: AVCaptureSession?
    var movieOutput: AVCaptureMovieFileOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureModeDelegate: CaptureModeDelegate?
    var recordingCompleteCenterX: NSLayoutConstraint?
    var recording = false
    var authorized = false
    
    @IBOutlet weak var timeBar: UIView!
    @IBOutlet weak var timeBarCenterX: NSLayoutConstraint!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: CaptureViewButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("viewBounds in didLoad: \(self.view.bounds.width)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if authorized {
            previewLayer!.frame = cameraView.bounds
            print("viewBounds in didAppear: \(self.view.bounds.width)")
            resetRecordInterface()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        recordingCompleteCenterX = timeBarCenterX
        print("viewBounds in willAppear: \(self.view.bounds.width)")
        timeBar.alpha = 0.0
        checkCameraAccess()
    }
    
    private func checkCameraAccess() {
        let camera: PrivateResource = .Camera
        proposeToAccess(camera, agreed: {
            self.authorized = true
            self.initCapturePreview()
        }, rejected: {
            print("Shut down")
            AppDelegate.getAppDelegate().showSettingsAlert("Can't Access Camera", message: "Allow Loopy to access your camera in Settings.")
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // called whenever recording mode exits. 
    // Hides the the recording bar and resets the button
    private func resetRecordInterface(){
        print("current centerX: \(timeBarCenterX!.constant)")
        if timeBarCenterX.constant == 0 {
            timeBarCenterX.constant = recordingCompleteCenterX!.constant - self.view.bounds.width
        }
        print("reset centerX: \(timeBarCenterX!.constant)")
        timeBar.hidden = true
        recordButton.recordingMode = false
        recordButton.setNeedsDisplay()
        self.view.layoutIfNeeded()
    }
    
    
    private func initCapturePreview() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1280x720
        let backCam = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let input = try AVCaptureDeviceInput(device: backCam)
            if captureSession!.canAddInput(input) {
                captureSession?.addInput(input)
                movieOutput = AVCaptureMovieFileOutput()
                movieOutput!.maxRecordedDuration = CMTimeMake(6, 1)
                if captureSession!.canAddOutput(movieOutput) {
                    captureSession?.addOutput(movieOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    cameraView.layer.addSublayer(previewLayer!)
                    captureSession!.commitConfiguration() //5
                    captureSession?.startRunning()
                }
                
            }
        } catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }

    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!,
                       didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!,
                       fromConnections connections: [AnyObject]!, error: NSError!) {
        // TODO: error check
        captureModeDelegate!.previewModeDidStart(outputFileURL)
    }
    
    // captureMode is the live preview mode
    func captureModeDidStart() {
        recordButton.hidden = false
        print("reset centerX: \(timeBarCenterX!.constant)")
        resetRecordInterface()
    }
    
    @IBAction func didPressRecord(sender: AnyObject) {
        let timeInterval = Int(NSDate().timeIntervalSince1970)
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "\(timeInterval).MOV")
        if !recording {
            movieOutput!.startRecordingToOutputFileURL(fileURL, recordingDelegate: self)
            recording = true
            startRecordInterface()
        } else {
            recording = false
            movieOutput!.stopRecording()
            resetRecordInterface()
        }
    }
    
    private func startRecordInterface() {
        recordButton.recordingMode = true
        recordButton.setNeedsDisplay()
        timeBar.hidden = false
        UIView.animateWithDuration(6, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.timeBarCenterX.constant = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}