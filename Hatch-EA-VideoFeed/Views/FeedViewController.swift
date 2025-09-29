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
    // Data
    @ObservedObject var viewModel: FeedViewModel
    private var cancellables = Set<AnyCancellable>()

    // UI
    var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private var cellHeight: CGFloat?

    private var currentIndex: Int = 0
    
    // MARK: Init
    init(vm: FeedViewModel) {
        self.viewModel = vm
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        view.backgroundColor = .black
        
        setupCollectionView()
        
        viewModel.updateNeighborPlayers()
        
        setupViewModelPublishers()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        cellHeight = layout.itemSize.height
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        
        // Configure collection view for full-screen vertical paging (like TikTok/Instagram Reels).
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        collectionView.register(FeedCollectionViewCell.self, forCellWithReuseIdentifier: FeedCollectionViewCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupViewModelPublishers() {
        viewModel.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                switch isPlaying {
                case true:
                        self?.viewModel.playCurrentItem()
                case false:
                        self?.viewModel.pauseCurrentItem()
                }
            }
            .store(in: &cancellables)
            
        viewModel.$videoURLs
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$isTyping
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTyping in
                switch isTyping {
                case true:
                    self?.viewModel.pauseCurrentItem()
                    self?.collectionView.isScrollEnabled = false
                case false:
                    self?.viewModel.playCurrentItem()
                    self?.collectionView.isScrollEnabled = true
                }
            }
            .store(in: &cancellables)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }

}

// MARK: CollectionView Methods
extension FeedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.videoURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedCollectionViewCell.identifier, for: indexPath) as! FeedCollectionViewCell
        guard let video = viewModel.videoURLs[safe: indexPath.row] else { return cell }
        let player = viewModel.playerPool.player(forIndex: indexPath.row, withURL: video)
        cell.configure(with: player)
        if !viewModel.isPlaying {
            cell.player?.play()
                viewModel.isPlaying = true
        }
        return cell
    }
}

extension FeedViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if viewModel.canScroll {
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
        viewModel.didScroll(scrollView, cellHeight: cellHeight)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cellHeight else { return }
        let index = CGFloat(scrollView.contentOffset.y) / cellHeight
        currentIndex = Int(index)
        viewModel.didEndScrollToIndex(currentIndex)
    }
    
}

// MARK: CollectionView Prefetch
extension FeedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let index = indexPath.row
            guard let video = viewModel.videoURLs[safe: index] else { return }
//             Fetching player from player pool causes AVPlayer to automatically start buffering the video data
            let player = viewModel.playerPool.player(forIndex: index, withURL: video)
            Task {
                try await player.currentItem?.asset.loadTracks(withMediaType: .video)
            }
        }
    }

}
