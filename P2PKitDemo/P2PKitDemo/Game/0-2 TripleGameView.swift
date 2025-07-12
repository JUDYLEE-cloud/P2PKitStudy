//
//  GameTab.swift
//  P2PKitDemo

import SwiftUI
import P2PKit

struct TripleGameView: View {
    @EnvironmentObject var router: AppRouter

    @StateObject private var connected = DuoConnectedPeers()
    @State private var state: TripleGameTabState = .unstarted
    
    @State private var countdown: Int? = nil
    @State private var countdownTimer: Timer? = nil

    var body: some View {
        ZStack {
            VStack {
                Group {
                    Text("3인 게임")
                    Text("채널: \(P2PConstants.networkChannelName)")
                    Button {
                        P2PNetwork.outSession()
                        connected.out()
                        router.currentScreen = .gameStart
                    } label: {
                        Image(systemName: "door.left.hand.open")
                    }
                }

                if state == .unstarted {
                    LobbyView(connected: connected) {
                        if connected.peers.count == 2 {
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
                } else if state == .pausedGame {
                    LobbyView(connected: connected) {
                        BigButton("오류 발생. 다시 돌아가기") {
                            P2PNetwork.outSession()
                            P2PNetwork.removeAllDelegates()
                            router.currentScreen = .gameStart
                        }
                    }
                    .background(.white)
                } else {
                    GameView()
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
            } else if connectedCount == 2 && state == .unstarted {
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

private enum TripleGameTabState {
    case unstarted
    case startedGame
    case pausedGame
}
