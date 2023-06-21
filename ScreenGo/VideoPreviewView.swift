//
//  PreviewView.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

import AVFoundation
import SwiftUI

struct VideoPreviewView: UIViewRepresentable {
    @Binding var session: AVCaptureSession
    @EnvironmentObject var appDelegate: AppDelegate

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        previewLayer.connection?.videoRotationAngle = 0
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?[0] as? AVCaptureVideoPreviewLayer {
            layer.session = session
            layer.frame = uiView.bounds
            layer.connection?.automaticallyAdjustsVideoMirroring = false
            layer.connection?.isVideoMirrored = false

            switch appDelegate.orientation {
            case .portrait, .portraitUpsideDown:
                layer.connection?.videoRotationAngle = 180
            case .landscapeLeft, .landscapeRight:
                layer.connection?.videoRotationAngle = 0
            default:
                layer.connection?.videoRotationAngle = 0
            }
        }
    }
}
