//
//  GameTab.swift
//  P2PKitDemo

import SwiftUI
import P2PKit

struct DuoGameView: View {
    @StateObject private var connected = DuoConnectedPeers()
    @State private var state: DuoGameTabState = .unstarted
    
    @State private var countdown: Int? = nil
    @State private var countdownTimer: Timer? = nil

    var body: some View {
        ZStack {
            VStack {
                Text("2인 게임")
                Text("채널: \(P2PConstants.networkChannelName)")
                
                if state == .unstarted {
                    LobbyView(connected: connected) {
                        if connected.peers.count == 1 {
                            if let countdown = countdown {
                                Text("게임이 \(countdown)초 후 시작됩니다")
                                    .font(.title)
                                    .padding()
                            } else {
                                Text("연결이 끊어졌습니다")
                                    .font(.title)
                                    .padding()
                            }
                        }
                    }
                } else {
                    GameView()
                    
                    if state == .pausedGame {
                        LobbyView(connected: connected) {
                            BigButton("오류 발생. 다시 돌아가기") {
                                P2PNetwork.makeMeHost()
                                // 수정
                            }
                        }
                        .background(.white)
                    }
                }
            }
            .border(Color.red, width: 10)
        }
        .onAppear {
            connected.start()
        }
        .onChange(of: connected.peers.count) {
            let connectedCount = connected.peers.count
            if connectedCount == 0 && state == .startedGame {
                state = .pausedGame
            } else if connectedCount == 1 && state == .unstarted {
                startCountdown()
            } else {
                countdown = nil
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
        }
    }
    

    private func BigButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Text(text).padding(10).font(.title)
        })
        .p2pButtonStyle()
    }

    private func startCountdown() {
        countdown = 5
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let current = countdown, current > 1 {
                countdown = current - 1
            } else {
                timer.invalidate()
                countdownTimer = nil
                if connected.peers.count == 1 {
                    P2PNetwork.makeMeHost()
                    state = .startedGame
                }
            }
        }
    }
}

private enum DuoGameTabState {
    case unstarted
    case startedGame
    case pausedGame
}
