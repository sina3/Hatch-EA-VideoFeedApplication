//
//  ContentView.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-24.
//

import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject var vm = FeedViewModel()
    @State var currentIndex: Int = 0
    @State var isTyping = false
//    @State var isPlaying = false
    
    var body: some View {
        FeedView(videoURLs: vm.videoURLs, currentIndex: $currentIndex)
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    VStack {
                        ControlBarView() { focus in
                            isTyping = focus
                        }
                            .padding()
                    }
                }
    }
}

#Preview {
    ContentView()
}
