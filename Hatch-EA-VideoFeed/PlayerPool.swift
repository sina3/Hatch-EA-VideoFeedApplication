//
//  PlayerPool.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-28.
//

import AVFoundation

final class PlayerPool {
    private var players: [AVQueuePlayer] = []
    private var indexedPlayers: [Int:AVQueuePlayer] = [:]
    private var indexedLoopers: [Int:AVPlayerLooper] = [:]
    let poolSize = 16
    
    init() {
        players = (0..<poolSize).map({ _ in AVQueuePlayer() })
    }
    
    func player(forIndex index: Int, withURL url: URL) -> AVQueuePlayer {
        if let p = indexedPlayers[index] { return p }
        
        let player = players.removeFirst()
        let keysToRemove = indexedPlayers.compactMap { key, value in
            value == player ? key : nil
        }
        keysToRemove.forEach { releasePlayer(forIndex: $0) }
        players.append(player)
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 5.0
        player.removeAllItems()
        player.replaceCurrentItem(with: playerItem)
        
        indexedPlayers[index] = player
        
        let looper = AVPlayerLooper(player: player, templateItem: playerItem)
        indexedLoopers[index] = looper
        return player
    }
    
    func releasePlayer(forIndex index: Int) {
        if let p = indexedPlayers.removeValue(forKey: index) {
            p.removeAllItems()
        }
        indexedLoopers[index] = nil
        print("DEBUG: Player for item \(index) was released")
    }
}
