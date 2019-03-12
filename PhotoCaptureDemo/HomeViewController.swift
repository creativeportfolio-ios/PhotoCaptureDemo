//
//  ViewController.swift
//  PhotoCaptureDemo
//
//  Copyright © 2019 A2B. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class HomeViewController: UIViewController {
    
    @IBOutlet weak var captureButton: UIButton!
    
    fileprivate struct Constants {
        static let keychainIndentifier = "com.sth.sth"
        static let service = "myService"
        static let account = "myAccount"
        static let alertTitle = "Alert"
        static let alertMessage = "Please enable camera permission from device setting"
        static let ok = "OK"
        static let interval = 0.5
        static let totalDuration = 5.0
        static let initialDuration = 0.0
    }
    
    private var cameraInput: AVCaptureDeviceInput!
    private var camera: AVCaptureDevice!
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoSettings = AVCapturePhotoSettings()
    private var timer = Timer()
    private var currentDuration = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(checkCameraPermission),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkCameraPermission()
    }

    func setupSession() {
        self.captureSession.beginConfiguration()
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            do {
                self.camera = camera
                cameraInput = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(cameraInput) {
                    captureSession.addInput(cameraInput)
                }
            } catch {
                print("Error setting device video input: \(error)")
            }
        }
        
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        guard self.captureSession.canAddOutput(photoOutput) else { return }
        self.captureSession.sessionPreset = .photo
        self.captureSession.addOutput(photoOutput)
        
        self.captureSession.commitConfiguration()
        self.captureSession.startRunning()
    }
    
    func setupPhotoSettings() {
        if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            photoSettings = AVCapturePhotoSettings(format:
                [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        photoSettings.flashMode = .auto
        photoSettings.isAutoStillImageStabilizationEnabled = self.photoOutput.isStillImageStabilizationSupported
    }
    
    @IBAction func capturePhoto(sender: UIButton) {
        timer = Timer.scheduledTimer(timeInterval: Constants.interval, target: self, selector: #selector(captureImage), userInfo: nil, repeats: false)
    }
    
    @objc func captureImage() {
        let currentSettings = getSettings(camera: self.camera, flashMode: .auto)
        self.photoOutput.capturePhoto(with: currentSettings, delegate: self)
        self.captureButton.isEnabled = false
    }
    
    func getSettings(camera: AVCaptureDevice, flashMode: AVCaptureDevice.FlashMode) -> AVCapturePhotoSettings {
        self.photoSettings = AVCapturePhotoSettings()
        if self.photoOutput.availablePhotoCodecTypes.contains(.h264) {
            photoSettings = AVCapturePhotoSettings(format:
                [AVVideoCodecKey: AVVideoCodecType.h264])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        photoSettings.flashMode = .auto
        photoSettings.isAutoStillImageStabilizationEnabled = self.photoOutput.isStillImageStabilizationSupported
        return photoSettings
    }
}

extension HomeViewController {
    @objc func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            self.openSettingScreen()
        case .restricted:
            self.openSettingScreen()
        case .authorized:
            self.setupSession()
            self.setupPhotoSettings()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                self.setupSession()
                self.setupPhotoSettings()
            }
        }
    }
    
    func openSettingScreen() {
        let alertController = UIAlertController(title: Constants.alertTitle, message: Constants.alertMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Constants.ok, style: .default, handler: { (alertAction) in
            let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, completionHandler: { (success) in
                })
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension HomeViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.");
            return
        }
        self.savePhoto(imageData: photoData)
    }
    
    func savePhoto(imageData: Data) {
        do {
            let videoData = try NSKeyedArchiver.archivedData(withRootObject: imageData, requiringSecureCoding: true)
            KeychainService.saveData(service: Constants.service, account: Constants.account, data: videoData)
            self.currentDuration += Constants.interval
            if self.currentDuration >= Constants.totalDuration {
                self.currentDuration = Constants.initialDuration
                self.timer.invalidate()
                self.captureButton.isEnabled = true
            }
            else {
                timer = Timer.scheduledTimer(timeInterval: Constants.interval, target: self, selector: #selector(captureImage), userInfo: nil, repeats: false)
                self.captureButton.isEnabled = false
            }
            // For Get photo checking
            //_ = getPhoto()
        }
        catch {
            
        }
    }
    
    func getPhoto() -> Data? {
        if let imageData = KeychainService.getData(service: Constants.service, account: Constants.account) {
            do {
                guard let imageData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as? Data else {
                    return nil
                }
                return imageData
            }
            catch {
                
            }
        }
        return nil
    }
}
