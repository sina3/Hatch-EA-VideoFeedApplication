//
//  NetworkManager.swift
//  Hatch-EA-VideoFeed
//
//  Created by Sina Rezazadeh on 2025-09-25.
//
import Foundation

struct Manifest: Decodable {
    let videos: [URL]
}

class NetworkManager {
    func fetchManifest() async throws -> Manifest {
        guard let url = Endpoint.videoFeed.url else { throw NetworkError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else { throw NetworkError.invalidResponse }
        guard let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { throw NetworkError.badData }
        return manifest
    }
}

enum Endpoint {
    case videoFeed
    
    var url: URL? {
        switch self {
        case .videoFeed:
            return URL(string: "https://cdn.dev.airxp.app/AgentVideos-HLS-Progressive/manifest.json")
        }
    }
}

enum NetworkError: Error {
    case badURL
    case invalidResponse
    case badData
}
