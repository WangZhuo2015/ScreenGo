//
//  CaptureInputSetup.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

import AVFoundation

import AVFoundation

class CaptureInputSetup {
    var setupResult: SessionSetupResult = .pending
    var videoInput: AVCaptureDeviceInput!

    func addVideoInput(_ session: AVCaptureSession) {
        do {
            let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified).devices.first

            guard let device = videoDevice else {
                setupResult = .configurationFailed
                return
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoInput = videoDeviceInput
            } else {
                setupResult = .configurationFailed
            }
        } catch {
            print("Could not add video device input to the session: \(error)")
            setupResult = .configurationFailed
        }
    }

    func addAudioInput(_ session: AVCaptureSession) {
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
                setupResult = .configurationFailed
            }
        } catch {
            print("Could not create audio device input: \(error)")
            setupResult = .configurationFailed
        }
    }
}
