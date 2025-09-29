//
//  FeedViewModel.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {
    let networkManager = NetworkManager()
    @Published var videoURLs: [URL] = []
    @Published var isPlaying = false
    
    init() {
        Task {
            await getVideos()
        }
    }
    
    private func getVideos() async {
        do {
            let manifest = try await networkManager.fetchManifest()
            videoURLs = manifest.videos
        } catch {
            print(error)
        }
    }
}
