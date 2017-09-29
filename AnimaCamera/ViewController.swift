//
//  ViewController.swift
//  Video
//
//  Created by guillaume on 13/02/2017.
//  Copyright © 2017 Guillaume Stagnaro. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

import ImageIO
class ViewController: UIViewController {
    
    @IBOutlet private weak var previewView: PreviewView!

    lazy var secondWindow = UIWindow()
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    
    var captureDeviceInput : AVCaptureDeviceInput? //AVCaptureDeviceInput()
    var captureVideoOutput : AVCaptureVideoDataOutput? // AVCaptureVideoDataOutput()
    
    var exposureLocked = false
    var focusValue: Float = 0.5
    var exposureValue: Float = 0.5
    
    var autoFocus = true
    var autoExposure = true
    var torch = false
    
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session
    
    //MARK: av
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = UIColor.black
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        registerSettingsBundle()
        updateFromDefaults()
        
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "autoFocus",
                                          options: [.new, .old, .initial, .prior],
                                          context: nil)
        
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "autoExposure",
                                          options: [.new, .old, .initial, .prior],
                                          context: nil)
        
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "torch",
                                          options: [.new, .old, .initial, .prior],
                                          context: nil)
        
        //Subscribing to a UIScreenDidConnect/DisconnectNotification to react to changes in the status of connected screens.
        let screenConnectionStatusChangedNotification = NotificationCenter.default
        
        screenConnectionStatusChangedNotification.addObserver(self, selector:(#selector(ViewController.screenConnectionStatusChanged)), name:NSNotification.Name.UIScreenDidConnect, object:nil)
        
        screenConnectionStatusChangedNotification.addObserver(self, selector:(#selector(ViewController.screenConnectionStatusChanged)), name:NSNotification.Name.UIScreenDidDisconnect, object:nil)
        
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTape(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        self.view.addGestureRecognizer(longPressGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        self.view.addGestureRecognizer(pinchGesture)
        
        let panExposureGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanExposure(_:)))
        panExposureGesture.minimumNumberOfTouches = 1
        panExposureGesture.maximumNumberOfTouches = 1
        self.view.addGestureRecognizer(panExposureGesture)
        
        let panFocusGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanFocus(_:)))
        panFocusGesture.minimumNumberOfTouches = 2
        panFocusGesture.maximumNumberOfTouches = 2
        self.view.addGestureRecognizer(panFocusGesture)
        
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        assert((deviceDiscoverySession.devices.count)>0, "no devices !!")
        
        captureDevice = deviceDiscoverySession.devices[0]
        beginSession()
    }
    
    func registerSettingsBundle(){
        UserDefaults.standard.register(defaults: [String:AnyObject]())
        UserDefaults.standard.synchronize()
    }
    
    func updateFromDefaults(){
        
        //Get the defaults
        let defaults = UserDefaults.standard
        
        //Set the controls to the default values.
        autoFocus = defaults.bool(forKey: "autoFocus")
        if autoFocus == true {
            enableAutofocus()
        }
        print("saved autoFocus: \(autoFocus)")
        
        autoExposure = defaults.bool(forKey: "autoExposure")
        if autoExposure == true {
            enableAutoExposure()
        }
        print("saved autoFocus: \(autoExposure)")
        
        torch = defaults.bool(forKey: "torch")
        setTorch(state: torch)
        print("saved torch: \(torch)")
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "autoFocus" || keyPath == "autoExposure" || keyPath == "torch"{
            print("updating key \(keyPath ?? "bug ?")")
            updateFromDefaults()
        }
 
    }
    
    @objc func defaultsChanged(){
        print("default changed")
        updateFromDefaults()
    }
    
    @objc
    func screenConnectionStatusChanged () {
        if UIScreen.screens.count == 1 {
          
            
        }   else {
            
//            let screens : Array = UIScreen.screens
//            let newScreen : AnyObject! = screens.last
//
//            secondWindow.frame = newScreen.bounds
//            secondWindow.screen = newScreen as! UIScreen
//
//            let secondView = UIView(frame: secondWindow.frame)
//            secondView.layer.addSublayer(previewView.videoPreviewLayer)
//
//            secondWindow.addSubview(secondView)
//            secondWindow.makeKeyAndVisible()
//
//            previewView.window!.makeKey()
            
        }
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async { [unowned self] in
            if let device = self.captureDevice{
                do {
                    try device.lockForConfiguration()
                    /*
                     Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                     Call set(Focus/Exposure)Mode() to apply the new point of interest.
                     */
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusPointOfInterest = devicePoint
                        device.focusMode = focusMode
                        self.focusValue = device.lensPosition
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                        device.exposurePointOfInterest = devicePoint
                        device.exposureMode = exposureMode
                        self.exposureValue = device.exposureTargetBias
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    func exposureTo(value: Float) {
        
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                return
            }
            
            let min = device.minExposureTargetBias
            let max = device.maxExposureTargetBias
            let exposure = value * (max - min)  + min;
            device.exposureMode = .locked
            device.setExposureTargetBias(exposure, completionHandler: { (time) -> Void in
                print("exposure to \(exposure)")
            })
            
            device.unlockForConfiguration()
        }
    }
    
    func exposureBy(value: Float) {
        
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                return
            }
            
            let min = device.minExposureTargetBias
            let max = device.maxExposureTargetBias
            
            let currentExposure = device.exposureTargetBias
            let targetExposure = currentExposure + value
            let exposure = fmin(max,fmax(min,targetExposure));
            
            device.exposureMode = .locked
            device.setExposureTargetBias(exposure, completionHandler: { (time) -> Void in
                print("exposure to \(exposure)")
            })
            
            device.unlockForConfiguration()
        }
    }
    
    func focusTo(value : Float) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                return
            }
            
            device.focusMode = .locked
            device.setFocusModeLocked(lensPosition: value, completionHandler: { (time) -> Void in
                print("focused to \(value)")
            })
            device.unlockForConfiguration()
        }
    }
    
    func focusBy(value : Float) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                return
            }
            
            let min:Float = 0.0
            let max:Float = 1.0
            
            let currentFocus = device.lensPosition
            let targetFocus = currentFocus + value
            let focus = fmin(max,fmax(min,targetFocus));
            
            device.focusMode = .locked
            device.setFocusModeLocked(lensPosition: focus, completionHandler: { (time) -> Void in
                print("focused to \(value)")
            })
            
            device.unlockForConfiguration()
        }
    }
    
    func enableAutofocus() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                return
            }
            
            device.focusMode = .continuousAutoFocus
           
            device.unlockForConfiguration()
        }
    }
    
    func enableAutoExposure() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
            } catch _ {
                return
            }
            
            device.exposureMode = .continuousAutoExposure
            device.unlockForConfiguration()
        }
    }
    
    func setTorch(state: Bool) {
        if let device = self.captureDevice{
            if device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = state == false ? .off : .on
                    device.unlockForConfiguration()
                } catch {
                    print("error!!")
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // gestures
    @objc
    func handleDoubleTape(_ gestureRecognizer: UITapGestureRecognizer) {
        if autoFocus == true {
            return
        }
        let devicePoint = self.previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .locked, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    @objc
    func handlePanExposure(_ gestureRecognize: UIPanGestureRecognizer) {
        if autoExposure == true {
            return
        }
        let exposure = gestureRecognize.translation(in: self.view).x/20.0
        gestureRecognize.setTranslation(CGPoint.zero, in: self.view)
        
        exposureBy(value: Float(exposure))
    }
    
    @objc
    func handlePanFocus(_ gestureRecognize: UIPanGestureRecognizer) {
        if autoFocus == true {
            return
        }
        let focus = gestureRecognize.translation(in: self.view).x/20.0
        gestureRecognize.setTranslation(CGPoint.zero, in: self.view)
        
        focusBy(value: Float(focus))
    }
    
    @objc
    func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began {
            return
        }
        if let device = self.captureDevice{
            if device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = device.torchMode == .on ? .off : .on
                    device.unlockForConfiguration()
                } catch {
                    print("error!!")
                }
            }
        }
    }
    
    @objc
    func handlePinch(_ gestureRecognize: UIPinchGestureRecognizer) {
        let pinchVelocityDividerFactor = 10.0
        if gestureRecognize.state == .changed {
            
        print("pinch")
            if let device = self.captureDevice{
                do {
                    try device.lockForConfiguration()
                    
                    let desireZoomFactor = (captureDevice?.videoZoomFactor)! + CGFloat(atan2(Double(gestureRecognize.velocity), Double(pinchVelocityDividerFactor)))
                    captureDevice?.videoZoomFactor = max(1.0, min(desireZoomFactor, (captureDevice?.activeFormat.videoMaxZoomFactor)!))
                    captureDevice?.unlockForConfiguration()
                } catch {
                    print("error!!")
                }
            }
        }
    }
    
    func beginSession() {
        
        do {
            print("begin session")
            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice!)
            
            captureSession.addInput(captureDeviceInput!)
            captureSession.startRunning()
           
            previewView.session = captureSession
            self.previewView.videoPreviewLayer.connection?.videoOrientation = .landscapeRight
            
        } catch _ {
            print("Error Starting Session")
            
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
}
