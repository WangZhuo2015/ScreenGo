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
    private var devicesObservation: NSKeyValueObservation?
    private var discoverySession: AVCaptureDevice.DiscoverySession?
    var externalDevices: [String]{
        get{
            self.discoverySession?.devices.map{$0.localizedName} ?? []
        }
    }
    
    func setup() {
        checkCameraAuthorization()
        configureSession()
        startSession()
        observeDeviceChanges()
    }
    
    private func observeDeviceChanges() {
        self.discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
        devicesObservation = discoverySession?.observe(\.devices, options: .new) { discoverySession, change in
            print("Devices changed: \(discoverySession.devices)")
            self.reconnectCaptureCard()
        }
    }
    
    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        self.setupResult = .notAuthorized
                    }
                }
                self.sessionQueue.resume()
            }
            
        default:
            DispatchQueue.main.async {
                self.setupResult = .notAuthorized
            }
        }
    }
    
    func reconnectCaptureCard(){
        if session.isRunning {
            session.stopRunning()
            print("session stopped")
        }
        configureSession()
        if setupResult == .success {
            startSession()
            print("session started")
        }
    }
    
    
    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1920x1080
            self.session.usesApplicationAudioSession = true
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified).devices
            guard let externalDevice = devices.first else {
                print("No external device found.")
                DispatchQueue.main.async {
                    self.setupResult = .configurationFailed
                }
                self.session.commitConfiguration()
                self.session.stopRunning()
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: externalDevice)
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                } else {
                    print("Couldn't add video device input to the session.")
                    DispatchQueue.main.async {
                        self.setupResult = .configurationFailed
                    }
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                print("Couldn't create video device input: \(error)")
                DispatchQueue.main.async {
                    self.setupResult = .configurationFailed
                }
                self.session.commitConfiguration()
                return
            }
            
            // Add an audio input device.
            do {
                let audioDevice = AVCaptureDevice.default(for: .audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
                if self.session.canAddInput(audioDeviceInput) {
                    self.session.addInput(audioDeviceInput)
                } else {
                    print("Could not add audio device input to the session")
                }
                
                // Connect the audio engine's input and output only after the audio device input has been added to the session.
                self.audioEngine.connect(self.audioEngine.inputNode, to: self.audioEngine.outputNode, format: self.audioEngine.inputNode.inputFormat(forBus: 0))
                try self.audioEngine.start()
            } catch {
                print("Could not create audio device input: \(error)")
            }
            
            let photoOutput = AVCaptureMovieFileOutput()
            if self.session.canAddOutput(photoOutput) {
                self.session.addOutput(photoOutput)
            } else {
                print("Could not add photo output to the session")
                DispatchQueue.main.async {
                    self.setupResult = .configurationFailed
                }
                self.session.commitConfiguration()
                return
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
