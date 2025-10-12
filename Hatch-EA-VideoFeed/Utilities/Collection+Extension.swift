//
//  Collection+Extension.swift
//  InfiniteVideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
