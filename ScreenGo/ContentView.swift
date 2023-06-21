//
//  ContentView.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject var appDelegate: AppDelegate

    var body: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                Text(viewModel.externalDevices.first ?? "No device connected")
//                Text("Resolution: 1920*1080")
                Spacer()
                Button("Reconnect Capture Card"){
                    viewModel.reconnectCaptureCard()
                }
                Spacer()
            }
            VideoPreviewView(session: $viewModel.session)
                .onAppear(perform: viewModel.setup)
                .environmentObject(appDelegate)
            Spacer()
        }
        
    }
}
