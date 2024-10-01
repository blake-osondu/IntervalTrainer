//
//  MusicKitClient.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import MusicKit
import Dependencies

struct MusicKitClient {
    var requestAuthorization: @Sendable () async -> MusicAuthorization.Status
    var fetchRecentPlaylist: @Sendable () async -> Playlist?
    var play: @Sendable () async -> Void
    var pause: @Sendable () async -> Void
    var skipToNextItem: @Sendable () async -> Void
    var skipToPreviousItem: @Sendable () async -> Void
}

extension MusicKitClient: DependencyKey {
    static let liveValue = Self(
        requestAuthorization: {
            await MusicAuthorization.request()
        },
        fetchRecentPlaylist: {
            do {
                let request = MusicLibraryRequest<Playlist>()
                let response = try await request.response()
                return response.items.first
            } catch {
                print("Error fetching recent playlist: \(error)")
                return nil
            }
        },
        play: {
            #if os(iOS)
                try? await ApplicationMusicPlayer.shared.play()
            #endif
        },
        pause: {
            #if os(iOS)
           ApplicationMusicPlayer.shared.pause()
            #endif
        },
        skipToNextItem: {
            #if os(iOS)
            try? await ApplicationMusicPlayer.shared.skipToNextEntry()
            #endif
        },
        skipToPreviousItem: {
            #if os(iOS)
            try? await ApplicationMusicPlayer.shared.skipToPreviousEntry()
            #endif
        }
    )
}

extension DependencyValues {
    var musicKitClient: MusicKitClient {
        get { self[MusicKitClient.self] }
        set { self[MusicKitClient.self] = newValue }
    }
}

// For testing and previews
extension MusicKitClient: TestDependencyKey {
    static let testValue = Self(
        requestAuthorization: { .authorized },
        fetchRecentPlaylist: {
            return nil
        },
        play: {},
        pause: {},
        skipToNextItem: {},
        skipToPreviousItem: {}
    )
}
