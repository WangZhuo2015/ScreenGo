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
                Text("Device: external capture")
                Text("Resolution: 1920*1080")
            }
            VideoPreviewView(session: $viewModel.session)
                .onAppear(perform: viewModel.setup)
                .environmentObject(appDelegate)
            Spacer()
        }
        
    }
}
