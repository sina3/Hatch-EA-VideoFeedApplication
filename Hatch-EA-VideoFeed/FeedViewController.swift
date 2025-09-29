//
//  FeedViewController.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

class FeedViewController: UIViewController {
    private var videos: [URL] = []
    private var playerPool = PlayerPool()
    private var canScroll: Bool = true
    private var readinessTimer: Timer?
    private var cellHeight: CGFloat?
    private var nextItemVisible = false
    private var previousItemVisible = false
    private var previousPlayer: AVQueuePlayer?
    private var currentPlayer: AVQueuePlayer?
    private var nextPlayer: AVQueuePlayer?
    var isPlaying = false
    var isTyping = false
    var subscriptions = Set<AnyCancellable>()
    
    var collectionView: UICollectionView!
    
    private var currentIndex: Int = 0
    
    var onIndexChange: (Int) -> Void = {_ in }
    
    override func viewDidLoad() {
        view.backgroundColor = .black
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        cellHeight = layout.itemSize.height
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        collectionView.register(FeedCollectionViewCell.self, forCellWithReuseIdentifier: FeedCollectionViewCell.identifier)
        
        view.addSubview(collectionView)

        updateNeighborPlayers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
        
    func updateState(videos: [URL]) {
        self.videos = videos
        collectionView.reloadData()
    }

}

extension FeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedCollectionViewCell.identifier, for: indexPath) as! FeedCollectionViewCell
        guard let video = videos[safe: indexPath.row] else { return cell }
        let player = playerPool.player(forIndex: indexPath.row, withURL: video)
        cell.configure(with: player)
        if !isPlaying {
            cell.player?.play()
            isPlaying = true
        }
        print("DEBUG: Fetching cell for item \(indexPath.row)")
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        releaseFarAwayPlayers()
        print("DEBUG: will display Item \(indexPath.row)")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        togglePlayback()
    }
    
    func togglePlayback() {
        if isPlaying {
            currentPlayer?.pause()
            isPlaying = false
        } else {
            currentPlayer?.play()
            isPlaying = true
        }
    }
    
    func checkNextItemReadiness() {
        guard let nextPlayer = nextPlayer else { return }
        canScroll = false
        subscriptions.forEach({ $0.cancel() })
        print("DEBUG: Next video is ready: \(canScroll)")
        nextPlayer.publisher(for: \.status)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                        self.canScroll = true
                        print("DEBUG: Next video is ready: \(self.canScroll)")
                case .failed:
                    // Handle video failed.
                    print("DEBUG: Next video player failed")
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
    
    func releaseFarAwayPlayers() {
        let beforeRange = currentIndex - 6 ... currentIndex - 3
        let afterRange = currentIndex + 3 ... currentIndex + 6
        for index in beforeRange { playerPool.releasePlayer(forIndex: index) }
        for index in afterRange { playerPool.releasePlayer(forIndex: index) }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
}

extension FeedViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        updateNeighborCells()
        if canScroll {
            collectionView.isScrollEnabled = true
        } else {
            collectionView.isScrollEnabled = false
            showVisualFeedback(in: view)
        }
    }
    
    func showVisualFeedback(in parentView: UIView) {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.octagon.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animateKeyframes(
            withDuration: 0.5,
            delay: 0) {
                UIView.addKeyframe(
                    withRelativeStartTime: 0,
                    relativeDuration: 0.1) {
                        imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                UIView.addKeyframe(
                    withRelativeStartTime: 0.3,
                    relativeDuration: 0.2) {
                        imageView.alpha = 0
                    }
            } completion: { [weak self] _ in
                imageView.removeFromSuperview()
                self?.collectionView.isScrollEnabled = true
            }

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cellHeight else { return }
        let relativeOffset = scrollView.contentOffset.y - (CGFloat(currentIndex) * cellHeight)
        if relativeOffset > (cellHeight * 0.3) {
            updateNeighborPlayers()
            if !nextItemVisible {
                nextItemVisible = true
                currentPlayer?.pause()
                nextPlayer?.play()
            }
        } else if relativeOffset < (-cellHeight * 0.3) {
            updateNeighborPlayers()
            if !previousItemVisible {
                previousItemVisible = true
                currentPlayer?.pause()
                previousPlayer?.play()
            }
        } else if nextItemVisible || previousItemVisible {
            updateNeighborPlayers()
            currentPlayer?.play()
            previousPlayer?.pause()
            nextPlayer?.pause()
            nextItemVisible = false
            previousItemVisible = false
        }
    }
    
    private func updateNeighborPlayers() {
        if let previusVideo = videos[safe: currentIndex - 1] {
            previousPlayer = playerPool.player(forIndex: currentIndex - 1, withURL: previusVideo)
        }
        if let currentVideo = videos[safe: currentIndex] {
            currentPlayer = playerPool.player(forIndex: currentIndex, withURL: currentVideo)
        }
        if let nextVideo = videos[safe: currentIndex + 1] {
            nextPlayer = playerPool.player(forIndex: currentIndex + 1, withURL: nextVideo)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cellHeight else { return }
        let index = CGFloat(scrollView.contentOffset.y) / cellHeight
        currentIndex = Int(index)
        updateNeighborPlayers()
        checkNextItemReadiness()
        startReadinessTimer()
        onIndexChange(currentIndex)
    }
    
    func startReadinessTimer() {
        readinessTimer?.invalidate()
        readinessTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] _ in
            self?.checkNextItemReadiness()
        })
    }

}

extension FeedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let index = indexPath.row
            guard let video = videos[safe: index] else { return }
            // Fetching player from player pool causes AVPlayer to automatically start buffering the video data
            let _ = playerPool.player(forIndex: index, withURL: video)
            print("DEBUG: Prefetching index \(index)")
        }
    }
    
    
}
