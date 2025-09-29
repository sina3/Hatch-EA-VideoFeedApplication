//
//  FeedCollectionViewCell.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

class FeedCollectionViewCell: UICollectionViewCell {
    static let identifier = "FeedCell"
    var player: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?
    
    func configure(with player: AVQueuePlayer) {
        if self.player == nil {
            self.player = player
            let playerlayer = AVPlayerLayer(player: player)
            playerlayer.frame = contentView.frame
            playerlayer.videoGravity = .resizeAspectFill
            contentView.layer.addSublayer(playerlayer)
        }
    }
    
    func configure(with video: URL) {
        let playerItem = AVPlayerItem(url: video)
        player = AVQueuePlayer(playerItem: playerItem)
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = contentView.frame
        playerLayer.videoGravity = .resizeAspectFill
        contentView.layer.addSublayer(playerLayer)
        player?.play()
        
    }
    
    override func prepareForReuse() {
        player = nil
        playerLooper = nil
    }

}
