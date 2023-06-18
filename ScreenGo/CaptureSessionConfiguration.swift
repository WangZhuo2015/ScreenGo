//
//  CaptureSessionConfiguration.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

import AVFoundation

class CaptureSessionConfiguration {

    static func requestPermissionAndConfigureSession(_ session: AVCaptureSession, _ sessionQueue: DispatchQueue, _ setupResult: SessionSetupResult) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupResult = .success
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    setupResult = .notAuthorized
                }
                sessionQueue.resume()
            }
            
        default:
            setupResult = .notAuthorized
        }
        
        if setupResult == .success {
            configureSession(session)
        } else {
            DispatchQueue.main.async {
                showingAlert = true
            }
        }
    }

    private static func configureSession(_ session: AVCaptureSession) {
        session.beginConfiguration()

        session.sessionPreset = .hd1920x1080
        CaptureInputSetup.addVideoInput(session, setupResult)
        CaptureInputSetup.addAudioInput(session, setupResult)
        CaptureOutputSetup.addMovieOutput(session, setupResult)

        session.commitConfiguration()
        
        if setupResult == .success {
            session.startRunning()
        } else {
            DispatchQueue.main.async {
                showingAlert = true
            }
        }
    }
}
