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
    var isConfigured = false
    private var videoIsReadyToPlay = false {
        didSet {
            if videoIsReadyToPlay {
                loadingSpinner?.stopAnimating()
                setNeedsDisplay()
                print("DEBUG: Set needs display")
            } else {
                loadingSpinner?.startAnimating()
            }
        }
    }
    private var subscriptions = Set<AnyCancellable>()
    private var loadingSpinner: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLoadingSpinner()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoadingSpinner()
    }
    
    private func setupLoadingSpinner() {
        loadingSpinner = UIActivityIndicatorView(style: .large)
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.color = .white
        loadingSpinner.startAnimating()
        
        contentView.addSubview(loadingSpinner)
        
        NSLayoutConstraint.activate([
            loadingSpinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with player: AVQueuePlayer) {
        if !isConfigured {
            self.player = player
            let playerlayer = AVPlayerLayer(player: player)
            playerlayer.frame = contentView.frame
            playerlayer.videoGravity = .resizeAspectFill
            contentView.layer.insertSublayer(playerlayer, at: 0)
            isConfigured = true
        }
        checkForReadiness(for: player)
    }
    
    func checkForReadiness(for player:AVQueuePlayer) {
        player.publisher(for: \.status)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    self.videoIsReadyToPlay = true
                    print("DEBUG: Video is ready")
                default:
                    break
                }
            }
            .store(in: &subscriptions)
        
    }
    
    override func prepareForReuse() {
        isConfigured = false
        videoIsReadyToPlay = false
        player = nil
        playerLooper = nil
    }

}
