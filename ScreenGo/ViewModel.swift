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
    @Published var externalDevices: [String] = []
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
    func setup() {
        checkCameraAuthorization()
        configureSession()
        observeDeviceChanges()
    }
    
    private func observeDeviceChanges() {
        self.discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
        devicesObservation = discoverySession?.observe(\.devices, options: .new) { discoverySession, change in
            print("Devices changed: \(discoverySession.devices)")
            DispatchQueue.main.async {
                self.externalDevices = self.discoverySession?.devices.map{$0.localizedName} ?? []
            }
            self.sessionQueue.async {
                if discoverySession.devices.isEmpty{
                    if self.audioEngine.isRunning{
                        try! self.audioEngine.stop()
                    }
                    self.audioEngine.disconnectNodeInput(self.audioEngine.outputNode)
                    if self.session.isRunning{
                        self.session.stopRunning()
                    }
                    // remove all inputs and outputs
                    for input in self.session.inputs {
                        self.session.removeInput(input)
                    }
                    for output in self.session.outputs {
                        self.session.removeOutput(output)
                    }
                    
                }else{
                    self.reconnectCaptureCard()
                }
            }
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
    }
    
    
    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1920x1080
            self.session.usesApplicationAudioSession = true
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified).devices
            DispatchQueue.main.async {
                self.externalDevices = self.discoverySession?.devices.map{$0.localizedName} ?? []
            }
            
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
                    self.session.stopRunning()
                    return
                }
            } catch {
                print("Couldn't create video device input: \(error)")
                DispatchQueue.main.async {
                    self.setupResult = .configurationFailed
                }
                self.session.commitConfiguration()
                self.session.stopRunning()
                return
            }
            
            // delay 1 second to wait for audio device input to be added to the session
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.audioEngine.connect(self.audioEngine.inputNode, to: self.audioEngine.outputNode, format: self.audioEngine.inputNode.inputFormat(forBus: 0))
                try! self.audioEngine.start()
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
                self.session.stopRunning()
                return
            }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
}
