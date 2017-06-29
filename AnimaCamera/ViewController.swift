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
class ViewController: UIViewController, AVPlayerViewControllerDelegate {
    
    @IBOutlet private weak var previewView: PreviewView!
    
    var externalWindow:UIWindow!
    var externalScreen:UIScreen!
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var captureDeviceInput = AVCaptureDeviceInput()
    let captureVideoOutput = AVCaptureVideoDataOutput()
    
    
    var exposureLocked = false
    var focusValue: Float = 0.5
    var exposureValue: Float = 0.5
    
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session
    var liveOrNot = true
    
    //MARK: av
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = UIColor.black
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        previewLayer?.backgroundColor = UIColor.black.cgColor
        
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
     
        self.view.addGestureRecognizer(panExposureGesture)
        
        
        captureSession.sessionPreset = AVCaptureSessionPreset1920x1080

        let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back)
        assert((deviceDiscoverySession?.devices.count)!>0, "no devices !!")
        
        captureDevice = deviceDiscoverySession?.devices[0]
        beginSession()
    }
    
    private func focus(with focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
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
            device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
                print("focused to \(value)")
            })
            device.unlockForConfiguration()
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // gestures
    func handleDoubleTape(_ gestureRecognizer: UITapGestureRecognizer) {
        print("double tap")
       
        let devicePoint = self.previewView.videoPreviewLayer.captureDevicePointOfInterest(for: gestureRecognizer.location(in: gestureRecognizer.view))
        //        focus(with: .autoFocus, exposureMode: (exposureLocked ?.autoExpose:.continuousAutoExposure), at: devicePoint, monitorSubjectAreaChange: true)
        focus(with: .autoFocus, exposureMode: .locked, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    func handlePanExposure(_ gestureRecognize: UIPanGestureRecognizer) {
         //if gestureRecognize.state == .began {
                   //}
        let exposure = gestureRecognize.translation(in: self.view).x/20.0
        gestureRecognize.setTranslation(CGPoint.zero, in: self.view)
        
        //print("pan\(exposure)")
        exposureBy(value: Float(exposure))
        //exposureTo(value: Float(focus))
    }
    
    func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began {
            return
        }
        if let device = self.captureDevice{
            if device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = device.torchMode == .on ? .off : .on
                } catch {
                    print("error!!")
                }
            }
        }
    }
    
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
            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(captureDeviceInput)
            captureSession.startRunning()
           
            previewView.session = captureSession
            self.previewView.videoPreviewLayer.connection.videoOrientation = .landscapeRight
            
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
