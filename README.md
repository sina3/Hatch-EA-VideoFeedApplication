
# Infinite Video Feed – Architecture Document

## Overview

This project is a proof-of-concept iOS application that replicates the **infinite video feed** pattern seen in TikTok and Instagram Reels. The application takes a manifest of HLS video streams, preloads and manages playback, and provides a smooth user experience.

---

## Build Instructions

* Building the project should be very straightforward since the code is mostly self contained. Make sure network connection is available to fetch manifest file and videos.

** Notes **
* Target version of iOS is set to 16 to allow a reasonable degree of backward compatibility.
* No external dependencies are required

---

## Architecture Approach

### High-Level Flow

* **SwiftUI Top Layer**
  Provides higher-level UI with `ContentView`, `FeedView`, and `ControlBarView`. SwiftUI is used for overlay controls, while UIKit manages the video feed for maximum performance.
* **FeedViewController**
  Housed in a `UIViewControllerRepresentible` struct, holds a `UICollectionView` configured for vertical paging. Responsible for UI setup, layout, and collection view prefetching.
* **FeedViewModel (ObservableObject)**
  Encapsulates feed state, playback coordination, and neighbor player management and other business logic to achieve separation of concerns and avoid bloating of `UIViewController`.
* **PlayerPool**
  Manages a fixed pool of `AVQueuePlayer` and `AVPlayerLooper` instances. Ensures reuse, looping, and helps with effiecient memory management.


---

## Key Design Decisions

* **UIKit for Core Feed, SwiftUI for Controls**
  `UICollectionView` offers sophisticated APIs for paging, prefetching, and reliable performance. SwiftUI overlays (text input, buttons) allow modern declarative UI and convenient implementation of behaviors and animations.

* **Player Reuse via Pooling**
  Instead of instantiating new players for every cell, the pool maintains a constant number (5). This supports video buffering without unbounded memory growth.

* **Neighbor Player Strategy**
  At any time, the feed holds references to `previousPlayer`, `currentPlayer`, and `nextPlayer`. This ensures seamless transitions when swiping, and also allows handing over the playback when peeking neighboring videos.

* **Playback Readiness Gate**
  At the end of each swipe to a new video, scrolling is temporarily disabled using a `canScroll` flag until the next video is buffered and ready (`AVPlayer.status == .readyToPlay`). This prevents black screens while waiting for network data.

---

## Smooth Transitions & Performance

* **Prefetching** (`UICollectionViewDataSourcePrefetching`) requests upcoming players ahead of scroll events, triggering asset buffering before needed.
* **Peek Logic** (`scrollViewDidScroll`) was used for early playback of the next/previous video when a user swipes past 30% of a screen height, mimicking TikTok’s feel.
* **AVPlayerLooper** guarantees videos repeat seamlessly without manual seeking.
* **UICollectionView** also provides built-in consideration of gesture velocity when user swipes.

---

## Network Efficiency

* **HLS Streams** allow adaptive bitrate streaming depending on network conditions. This is supported in `AVPlayer` and `AVFoundation` out of the box which provides a great deal of optimization.
* Prefetching takes advantage of built-in prefetching mechanism in `UICollectionView` and loads only the items requested to be prefetched, avoiding excessive bandwidth use.
* A **5-second readiness timer** acts as a fallback for slow connections, ensuring scrolling will not remain locked in edge cases where the main publisher fails.

---

## User Experience

* I tried to provide the best possible user experience with the video feed similar to other applications. The app supports tap to Play/Pause, early playback when peeking to other videos and more.

* **Visual Feedback**

* If a user tries to scroll before the next video is ready, a red warning icon briefly animates to indicate the restriction.
  
* **Control Bar with Text Input**

  * Collapsible input with placeholder ("Send message").
  * Expands up to 5 lines, then scrolls internally.
  * Reaction buttons visible by default, hide when text box is focused, replaced with send button when typing.
  * Typing disables scrolling and pauses playback for focus.



---

## Assumptions for the Requirements

* I assumed the videos should aspect fill the screen since they had various sizes and resolutions.
* Some of the playback behavior for the feed was borrowed from similar apps like TikTok.

---

## Future Improvements

* Complete testing of business logic in the ViewModel.
* Error handling for failed HLS streams with graceful fallbacks.
* Adding mechanism to refresh manifest when user reaches near end of current manifest.
