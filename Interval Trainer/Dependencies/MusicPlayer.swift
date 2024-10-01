//
//  MusicPlayer.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/10/24.
//

import SwiftUI
import ComposableArchitecture
import MusicKit

// Use MusicKit types for Track and Playlist
typealias Track = MusicKit.Track
typealias Playlist = MusicKit.Playlist

@Reducer
struct MusicPlayerFeature {
    @ObservableState
    struct State: Equatable {
        var isAuthorized: Bool = false
        var trackTitle: String?
        var currentTrack: Track?
        var isPlaying: Bool = false
        var playlist: Playlist?
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    enum Action {
        case requestMusicAuthorization
        case musicAuthorizationResponse(Bool)
        case loadPlaylist
        case playlistLoaded(Playlist?)
        case togglePlayPause
        case nextTrack
        case previousTrack
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case okTapped
        }
    }
    
    @Dependency(\.musicKitClient) var musicKitClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .requestMusicAuthorization:
                return .run { send in
                    let status = await self.musicKitClient.requestAuthorization()
                    await send(.musicAuthorizationResponse(status == .authorized))
                }
                
            case let .musicAuthorizationResponse(isAuthorized):
                state.isAuthorized = isAuthorized
                if isAuthorized {
                    return .send(.loadPlaylist)
                } else {
                    state.alert = AlertState {
                        TextState("Music Access Required")
                    } actions: {
                        ButtonState(action: .okTapped) {
                            TextState("OK")
                        }
                    } message: {
                        TextState("Please allow access to Apple Music in Settings to use this feature.")
                    }
                    return .none
                }
                
            case .loadPlaylist:
                return .run { send in
                    let playlist = await self.musicKitClient.fetchRecentPlaylist()
                    await send(.playlistLoaded(playlist))
                }
                
            case let .playlistLoaded(playlist):
                state.playlist = playlist
                return .none
                
            case .togglePlayPause:
                state.isPlaying.toggle()
                return .run { [isPlaying = state.isPlaying] _ in
                    if isPlaying {
                        await self.musicKitClient.play()
                    } else {
                        await self.musicKitClient.pause()
                    }
                }
                
            case .nextTrack:
                return .run { _ in
                    await self.musicKitClient.skipToNextItem()
                }
                
            case .previousTrack:
                return .run { _ in
                    await self.musicKitClient.skipToPreviousItem()
                }
                
            case .alert(.presented(.okTapped)), .alert(.dismiss):
                state.alert = nil
                return .none
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

struct MusicPlayerView: View {
    let store: StoreOf<MusicPlayerFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                if viewStore.isAuthorized {
                    HStack {
                        Button(action: { viewStore.send(.previousTrack) }) {
                            Image(systemName: "backward.fill")
                        }
                        
                        Button(action: { viewStore.send(.togglePlayPause) }) {
                            Image(systemName: viewStore.isPlaying ? "pause.fill" : "play.fill")
                        }
                        
                        Button(action: { viewStore.send(.nextTrack) }) {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .font(.title2)
                    
                    if let track = viewStore.currentTrack {
                        Text(track.title)
                            .font(.caption)
                    }
                } else {
                    Button("Authorize Apple Music") {
                        viewStore.send(.requestMusicAuthorization)
                    }
                }
            }
            .onAppear {
//                viewStore.send(.requestMusicAuthorization)
            }
            .alert(
                store: store.scope(state: \.$alert, action: \.alert)
            )
        }
    }
}

// Preview providers
#Preview("Music Player - Authorized") {
    MusicPlayerView(
        store: Store(
            initialState: MusicPlayerFeature.State(
                isAuthorized: true,
                currentTrack: nil,
                isPlaying: true,
                playlist: nil
            ),
            reducer: {
                MusicPlayerFeature()
                    .dependency(\.musicKitClient, .testValue)
            }
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
   
}

#Preview("Music Player - Unauthorized") {
    MusicPlayerView(
        store: Store(
            initialState: MusicPlayerFeature.State(
                isAuthorized: false
            ),
            reducer: {
                MusicPlayerFeature()
                    .dependency(\.musicKitClient, .testValue)
            }
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
    
}
