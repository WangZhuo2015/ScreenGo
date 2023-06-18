//
//  CaptureOutputSetup.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

import AVFoundation

import AVFoundation

class CaptureOutputSetup: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    // Define movieOutput as a property of the class
    private let movieOutput = AVCaptureMovieFileOutput()
    var setupResult: SessionSetupResult = .pending
    
    // Change isRecording from a let constant to a var variable
    var isRecording: Bool = false

    // Method to start recording
    func startRecording(_ sessionQueue: DispatchQueue) {
        sessionQueue.async {
            if !self.movieOutput.isRecording {
                self.movieOutput.startRecording(to: self.outputFileURL, recordingDelegate: self)
            }
        }
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    // Method to stop recording
    func stopRecording(_ sessionQueue: DispatchQueue) {
        sessionQueue.async {
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
        }
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    // Method to add movie output
    func addMovieOutput(_ session: AVCaptureSession, _ setupResult: SessionSetupResult) {
        if session.canAddOutput(self.movieOutput) {
            session.addOutput(self.movieOutput)
            self.movieOutput.movieFragmentInterval = .invalid
        } else {
            print("Could not add movie output to the session")
            self.setupResult = .configurationFailed
        }
    }

    // Private method to get output file URL
    private var outputFileURL: URL {
        let outputDirectory = FileManager.default.temporaryDirectory
        let outputURL = outputDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        return outputURL
    }

    // AVCaptureFileOutputRecordingDelegate methods
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Did start recording: \(fileURL.absoluteString)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Did finish recording: \(outputFileURL.absoluteString)")
    }
}
