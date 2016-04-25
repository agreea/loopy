import UIKit
import AVFoundation
import Proposer

protocol CaptureModeDelegate {
    func previewModeDidStart(movieURL: NSURL)
    func captureModeDidStart()
    func didFinishUpload()
    func didEnterCamera()
    func didExitCamera()
}

var SessionRunningAndDeviceAuthorizedContext = "SessionRunningAndDeviceAuthorizedContext"
var CapturingStillImageContext = "CapturingStillImageContext"
var RecordingContext = "RecordingContext"

class CaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    var sessionQueue: dispatch_queue_t!
    var session: AVCaptureSession?
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var captureModeDelegate: CaptureModeDelegate? // MasterViewController
    var recordingCompleteCenterX: NSLayoutConstraint?
    var recording = false
    var authorized = false
    var isBackCam = true
    var runtimeErrorHandlingObserver: AnyObject?
    
    @IBOutlet weak var timeBar: UIView!
    @IBOutlet weak var timeBarCenterX: NSLayoutConstraint!
    
    @IBOutlet weak var previewView: AVCamPreviewView!
    @IBOutlet weak var recordButton: CaptureViewButton!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sessionQueue = dispatch_queue_create("session queue",DISPATCH_QUEUE_SERIAL)
        print("Assigned session queue")
        // Do any additional setup after loading the view.
        self.checkCameraAccess()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let frame = bottomView.frame
        let camWindowHeight = self.view.bounds.width * 1.25
        let desiredBottomViewHeight = self.view.bounds.height - camWindowHeight
        bottomViewHeight.constant = desiredBottomViewHeight
        bottomView.setNeedsLayout()
        print("BottomView should be: \(bottomViewHeight)")
        print("BottomView height: \(bottomView.frame.height)")
        resetRecordInterface()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        timeBar.hidden = true
        recordingCompleteCenterX = timeBarCenterX
        dispatch_async(self.sessionQueue, {
            //            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.Old , .New] , context: &SessionRunningAndDeviceAuthorizedContext)
            //            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options:[.Old , .New], context: &CapturingStillImageContext)
            //            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: [.Old , .New], context: &RecordingContext)
            //            NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
            
            weak var weakSelf = self
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.session, queue: nil, usingBlock: {
                (note: NSNotification?) in
                var strongSelf: CaptureViewController = weakSelf!
                dispatch_async(strongSelf.sessionQueue, {
                    //                    strongSelf.session?.startRunning()
                    if let sess = strongSelf.session{
                        sess.startRunning()
                    }
                    //                    strongSelf.recordButton.title  = NSLocalizedString("Record", "Recording button record title")
                })
                
            })
            self.session?.startRunning()
            
        })
        
    }
    
    func checkCameraAccess() {
        let camera: PrivateResource = .Camera
        proposeToAccess(camera, agreed: {
            self.authorized = true
            self.resetRecordInterface()
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
        if timeBarCenterX.constant == 0 {
            timeBarCenterX.constant = recordingCompleteCenterX!.constant - self.view.bounds.width
        }
        timeBar.hidden = true
        recordButton.recordingMode = false
        recordButton.setNeedsDisplay()
        self.view.layoutIfNeeded()
    }
    
    //    private func initCapturePreview() {
    //        initFrontCamPreview()
    //        initBackCamPreview()
    //    }
    
    //    private func initBackCamPreview() {
    //        let captureSession = AVCaptureSession()
    //        captureSession.sessionPreset = AVCaptureSessionPreset1280x720
    //        let backCam = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    //        do {
    //            let input = try AVCaptureDeviceInput(device: backCam)
    //            if captureSession.canAddInput(input) {
    //                captureSession.addInput(input)
    //                backOutput = AVCaptureMovieFileOutput()
    //                backOutput!.maxRecordedDuration = CMTimeMake(6, 1)
    //                if captureSession.canAddOutput(backOutput) {
    //                    captureSession.addOutput(backOutput)
    //                    backPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    //                    backPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
    //                    backPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
    //                    backView.layer.addSublayer(backPreviewLayer!)
    //                    captureSession.commitConfiguration() //5
    //                    captureSession.startRunning()
    //                }
    //
    //            }
    //        } catch let error as NSError {
    //            NSLog("\(error), \(error.localizedDescription)")
    //        }
    //    }
    
    @IBAction func didPressExitCam(sender: AnyObject) {
        captureModeDelegate?.didExitCamera()
    }
    
    @IBAction func didPressFlipCam(sender: AnyObject) {
        //        self..enabled = false
        self.recordButton.enabled = false
        
        dispatch_async(self.sessionQueue) {
            let currentVideoDevice:AVCaptureDevice = self.videoDeviceInput!.device
            let currentPosition: AVCaptureDevicePosition = currentVideoDevice.position
            var preferredPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.Unspecified
            
            switch currentPosition{
            case AVCaptureDevicePosition.Front:
                preferredPosition = AVCaptureDevicePosition.Back
            case AVCaptureDevicePosition.Back:
                preferredPosition = AVCaptureDevicePosition.Front
            case AVCaptureDevicePosition.Unspecified:
                preferredPosition = AVCaptureDevicePosition.Back
            }
            
            let device = CaptureViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
            } catch _ as NSError {
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            self.session!.beginConfiguration()
            self.session!.removeInput(self.videoDeviceInput)
            if self.session!.canAddInput(videoDeviceInput){
                //                NSNotificationCenter.defaultCenter().removeObserver(self, name:AVCaptureDeviceSubjectAreaDidChangeNotification, object:currentVideoDevice)
                //                NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: device)
                self.session!.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else{
                self.session!.addInput(self.videoDeviceInput)
            }
            self.session!.commitConfiguration()
            dispatch_async(dispatch_get_main_queue(), {
                self.recordButton.enabled = true
                //                let shouldMirrorVideo = preferredPosition == AVCaptureDevicePosition.Front
                //                self.setVideoPreviewAndOutputMirrored(shouldMirrorVideo)
                //                self.snapButton.enabled = true
                //                self.cameraButton.enabled = true
            })
        }
    }
    
    //    private func setVideoPreviewAndOutputMirrored(mirrored: Bool) {
    //        // set previewLayer
    //        let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
    //        previewLayer.connection.automaticallyAdjustsVideoMirroring = false
    //        previewLayer.connection.videoMirrored = mirrored
    //        // set preview
    //        for connection in self.movieFileOutput!.connections {
    //            for port in connection.inputPorts! {
    //                if port.mediaType == AVMediaTypeVideo {
    //                    let videoConnection = connection as? AVCaptureConnection
    //                    if videoConnection!.supportsVideoMirroring {
    //                        videoConnection!.videoMirrored = mirrored
    //                    }
    //                }
    //            }
    //        }
    //    }
    func initCapturePreview() {
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session
        self.previewView.session = session
        dispatch_async(self.sessionQueue, {
            let videoDevice: AVCaptureDevice! = CaptureViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.Back)
            var error: NSError? = nil
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch let error1 as NSError {
                error = error1
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            if (error != nil) {
                AppDelegate.getAppDelegate().showError("Camera Error", message: error!.localizedDescription)
                print(error)
            }
            if self.session!.canAddInput(videoDeviceInput){
                self.session!.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                dispatch_async(dispatch_get_main_queue(), {
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    self.previewView.layer.frame = self.view.bounds
                    self.session!.commitConfiguration()
                    self.session!.startRunning()
                })
            }
            
            
            //            let audioDevice: AVCaptureDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).first as! AVCaptureDevice
            //
            //            var audioDeviceInput: AVCaptureDeviceInput?
            //
            //            do {
            //                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            //            } catch let error2 as NSError {
            //                error = error2
            //                audioDeviceInput = nil
            //            } catch {
            //                fatalError()
            //            }
            //            if error != nil{
            //                print(error)
            //                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
            //                    , preferredStyle: .Alert)
            //                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            //                self.presentViewController(alert, animated: true, completion: nil)
            //            }
            //            if session.canAddInput(audioDeviceInput){
            //                session.addInput(audioDeviceInput)
            //            }
            
            let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput){
                movieFileOutput.maxRecordedDuration = CMTimeMake(6, 1)
                session.addOutput(movieFileOutput)
                
                //                let connection: AVCaptureConnection? = movieFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                //                let stab = connection?.supportsVideoStabilization
                //                if (stab != nil) {
                //                    connection!.enablesVideoStabilizationWhenAvailable = true
                //                }
                self.movieFileOutput = movieFileOutput
            }
            //            let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            //            if session.canAddOutput(stillImageOutput){
            //                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            //                session.addOutput(stillImageOutput)
            //
            //                self.stillImageOutput = stillImageOutput
            //            }
            
            
        })
        
    }
    
    class func deviceWithMediaType(mediaType: String, preferringPosition:AVCaptureDevicePosition)->AVCaptureDevice{
        var devices = AVCaptureDevice.devicesWithMediaType(mediaType);
        var captureDevice = devices[0] as! AVCaptureDevice;
        for device in devices{
            if device.position == preferringPosition{
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
        
        
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
        resetRecordInterface()
    }
    
    @IBAction func didPressRecord(sender: AnyObject) {
        if !recording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        let timeInterval = Int(NSDate().timeIntervalSince1970)
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory() + "\(timeInterval).MOV")
        if movieFileOutput != nil {
            movieFileOutput!.startRecordingToOutputFileURL(fileURL, recordingDelegate: self)
        } else {
            AppDelegate.getAppDelegate().showError("Camera Error", message: "Please exit the camera and try again")
        }
        recording = true
        startRecordInterface()
    }
    
    private func stopRecording() {
        recording = false
        movieFileOutput!.stopRecording()
        resetRecordInterface()
    }
    
    private func startRecordInterface() {
        recordButton.recordingMode = true
        recordButton.setNeedsDisplay()
        timeBar.hidden = false
        print("BottomView height: \(bottomViewHeight.constant)")
        UIView.animateWithDuration(6, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.timeBarCenterX.constant = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

class AVCamPreviewView: UIView{
    
    var session: AVCaptureSession? {
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session;
        }
        set(session){
            (self.layer as! AVCaptureVideoPreviewLayer).session = session;
        }
    };
    
    override class func layerClass() ->AnyClass{
        return AVCaptureVideoPreviewLayer.self;
    }
}