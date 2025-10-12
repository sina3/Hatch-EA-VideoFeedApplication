//
//  FeedViewModel.swift
//  InfiniteVideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import AVFoundation
import Foundation
import Combine
import UIKit

class FeedViewModel: ObservableObject {
    let networkManager = NetworkManager()
    var playerPool = PlayerPool()
    
    // MARK: Published Properties
    @Published var videoURLs: [URL] = []
    @Published var isPlaying = false
    @Published var isTyping = false
    
    var canScroll: Bool = true
    
    private var currentIndex = 0

    // MARK: Neighbor Checks
    private var nextItemVisible = false
    private var previousItemVisible = false
    private var previousPlayer: AVQueuePlayer?
    private var currentPlayer: AVQueuePlayer?
    private var nextPlayer: AVQueuePlayer?
    private var areNeighborPlayersUpdated = false {
        didSet {
            if !areNeighborPlayersUpdated {
                updateNeighborPlayers()
            }
        }
    }
    private var readinessTimer: Timer?
    private var readinessSubscriptions = Set<AnyCancellable>()
    
    
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
    
    // MARK: Delegate Methods
    
    /// called in scrollView delegate methods. Used to update playback state of neighboring players while peeking up or down.
    /// If user scrolls more than 30% of cell height, start "peeking" into neighbor video.
    func didScroll(_ scrollView: UIScrollView, cellHeight: CGFloat) {
        let relativeOffset = scrollView.contentOffset.y - (CGFloat(currentIndex) * cellHeight)
        if relativeOffset > (cellHeight * 0.3) {
            if !nextItemVisible {
                nextItemVisible = true
                currentPlayer?.pause()
                nextPlayer?.play()
            }
        } else if relativeOffset < (-cellHeight * 0.3) {
            if !previousItemVisible {
                previousItemVisible = true
                currentPlayer?.pause()
                previousPlayer?.play()
            }
        } else if nextItemVisible || previousItemVisible {
            currentPlayer?.play()
            previousPlayer?.pause()
            nextPlayer?.pause()
            nextItemVisible = false
            previousItemVisible = false
        }
    }
    
    /// Update index after user finishes scrolling
    func didEndScrollToIndex(_ index: Int) {
        currentIndex = index
        nextItemVisible = false
        previousItemVisible = false
        areNeighborPlayersUpdated = false
        updateNeighborPlayers()
        
        // Lock scrolling until the next video is buffered and ready.
        canScroll = false
        checkNextItemReadiness()
        startReadinessTimer()
    }
    

    /// Update references to previous/current/next players based on current index
    func updateNeighborPlayers() {
        guard !areNeighborPlayersUpdated else { return }
        if let previusVideo = videoURLs[safe: currentIndex - 1] {
            previousPlayer = playerPool.player(forIndex: currentIndex - 1, withURL: previusVideo)
        }
        if let currentVideo = videoURLs[safe: currentIndex] {
            currentPlayer = playerPool.player(forIndex: currentIndex, withURL: currentVideo)
        }
        if let nextVideo = videoURLs[safe: currentIndex + 1] {
            nextPlayer = playerPool.player(forIndex: currentIndex + 1, withURL: nextVideo)
        }
        if currentIndex == 0 , !videoURLs.isEmpty {
            areNeighborPlayersUpdated = (currentPlayer != nil ) && (nextPlayer != nil )
        } else if currentIndex > 0 , currentIndex < videoURLs.count - 1 {
            areNeighborPlayersUpdated = (previousPlayer != nil ) && (currentPlayer  != nil ) && (nextPlayer  != nil )
        } else if currentIndex == videoURLs.count - 1 {
            areNeighborPlayersUpdated = (previousPlayer != nil ) && (currentPlayer  != nil )
        }
        
    }
    
    // MARK: Video Playback
    func playCurrentItem() {
        currentPlayer?.play()
    }
    
    func pauseCurrentItem() {
        currentPlayer?.pause()
    }
    
    func togglePlayback() {
        if isPlaying {
            pauseCurrentItem()
            isPlaying = false
        } else {
            playCurrentItem()
            isPlaying = true
        }
    }
    
    /// Checks if next video player is ready to play to set the canScroll flag
    func checkNextItemReadiness() {
        // Only check readiness if scrolling is locked
        guard !canScroll else {
            readinessTimer?.invalidate()
            return }
        guard let nextPlayer = nextPlayer else { return }
        readinessSubscriptions.forEach({ $0.cancel() })
        nextPlayer.publisher(for: \.status)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                if status == .readyToPlay {
                    self.canScroll = true
                }
            }
            .store(in: &readinessSubscriptions)
    }
    
    /// Starts a 5 seconds repeating timer to check next item's readiness. This is in case next player's publisher fails to publish.
    func startReadinessTimer() {
        readinessTimer?.invalidate()
        readinessTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] _ in
            self?.checkNextItemReadiness()
        })
    }
}
