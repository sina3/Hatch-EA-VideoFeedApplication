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
    @FocusState var isFocused
    
    var body: some View {
        FeedView(videoURLs: vm.videoURLs, currentIndex: $currentIndex, vm: vm)
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    VStack {
                        ControlBarView(isFocused: $isFocused, isTyping: $vm.isTyping)
                            .padding()
                    }
                }
                .onTapGesture {
                    vm.isPlaying.toggle()
                    isFocused = false
                    print("DEBUG: Content View tapped!")
                }
    }
}

#Preview {
    ContentView()
}
