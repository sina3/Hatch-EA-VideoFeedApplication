//
//  FeedView.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

import SwiftUI

struct FeedView: UIViewControllerRepresentable {
    
    let videoURLs: [URL]
    @Binding var currentIndex: Int
    
    func makeUIViewController(context: Context) -> FeedViewController {
        let vc = FeedViewController()
        vc.onIndexChange = { index in
            currentIndex = index
        }
        vc.view.isUserInteractionEnabled = true
        return vc
    }
    
    func updateUIViewController(_ uiViewController: FeedViewController, context: Context) {
        uiViewController.updateState(videos: videoURLs)
    }
    
}
