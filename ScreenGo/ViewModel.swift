//
//  ViewModel.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

private enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

import SwiftUI
import AVFoundation
class ViewModel: ObservableObject {
    enum SetupResult: String {
        case success = ""
        case notAuthorized = "App doesn't have permission to use the camera, please change privacy settings"
        case configurationFailed = "Unable to capture media"
    }
    
    @Published var setupResult: SetupResult = .success
    @Published var session = AVCaptureSession()
    @EnvironmentObject var appDelegate: AppDelegate
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let audioEngine = AVAudioEngine()
    private var isSessionRunning = false
    private let photoOutput = AVCaptureMovieFileOutput()
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    @objc dynamic var audioDeviceInput: AVCaptureDeviceInput!
    let captureAudioOutput = AVCaptureAudioDataOutput()
    
    func setup() {
        checkCameraAuthorization()
        configureSession()
        startSession()
    }
    
    private func checkCameraAuthorization() {
        audioEngine.connect(audioEngine.inputNode, to: audioEngine.outputNode, format: audioEngine.inputNode.inputFormat(forBus: 0))
        try! audioEngine.start()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            }
            
        default:
            setupResult = .notAuthorized
        }
    }
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1920x1080
            self.session.usesApplicationAudioSession = true
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified).devices
            let externalDevice = devices.first
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: externalDevice!)
                
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                } else {
                    print("Couldn't add video device input to the session.")
                    self.setupResult = .configurationFailed
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                print("Couldn't create video device input: \(error)")
                self.setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
            
            // Add an audio input device.
            do {
                let audioDevice = AVCaptureDevice.default(for: .audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
                print("Audio Device: \(String(describing: audioDevice?.localizedName))")
                if self.session.canAddInput(audioDeviceInput) {
                    print("Audio Device: \(String(describing: audioDevice?.localizedName)) Added")
                    self.session.addInput(audioDeviceInput)
                } else {
                    print("Could not add audio device input to the session")
                }
            } catch {
                print("Could not create audio device input: \(error)")
            }
            
            
            let photoOutput = AVCaptureMovieFileOutput()
            if self.session.canAddOutput(photoOutput) {
                self.session.addOutput(photoOutput)
            } else {
                print("Could not add photo output to the session")
                self.setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
            
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                // Set the audio session category and mode.
                try audioSession.setCategory(.playback, mode: .moviePlayback)
                try audioSession.setActive(true)
            } catch {
                print("Failed to set the audio session configuration")
            }
            self.session.commitConfiguration()
        }
    }
    
    private func startSession() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized, .configurationFailed:
                DispatchQueue.main.async {
                    self.setupResult = self.setupResult
                }
            }
        }
        
    }
}
