//
//  PlayerPool.swift
//  InfiniteVideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-28.
//

import AVFoundation

final class PlayerPool {
    private var players: [AVQueuePlayer] = []
    
    // Keeps track of which player is associated with which cell index.
    private var indexedPlayers: [Int:AVQueuePlayer] = [:]
    private var indexedLoopers: [Int:AVPlayerLooper] = [:]
    let poolSize = 5
    
    init() {
        players = (0..<poolSize).map({ _ in AVQueuePlayer() })
    }
    
    /// Fetches a player for the given feed index with the video URL
    func player(forIndex index: Int, withURL url: URL) -> AVQueuePlayer {
        if let player = indexedPlayers[index] {
            print("DEBUG: Existing player dequeued for index \(index)")
            return player }
        
        let player = players.removeFirst()
        players.append(player)

        // Release the player if it's indexed by other indexes
        let keysToRemove = indexedPlayers.compactMap { key , value in
            value == player ? key : nil
        }
        keysToRemove.forEach { releasePlayer(forIndex: $0) }
        
        player.removeAllItems()
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)
        
        print("DEBUG: player for index \(index) created")
        indexedPlayers[index] = player
        
        let looper = AVPlayerLooper(player: player, templateItem: playerItem)
        indexedLoopers[index] = looper
        return player
    }
    
    func releasePlayer(forIndex index: Int) {
        if let player = indexedPlayers.removeValue(forKey: index) {
            player.removeAllItems()
        }
        indexedLoopers[index] = nil
        print("DEBUG: Player for item \(index) was released")
    }
}
