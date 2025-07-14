//
//  0 GameStartView.swift
//  P2PKitDemo
//
//  Created by 이주현 on 7/8/25.
//

import SwiftUI
import P2PKit

func setupP2PKit(channel: String) {
    P2PConstants.networkChannelName = channel
    P2PConstants.loggerEnabled = true
}

struct GameStartTab: View {
    @EnvironmentObject var router: AppRouter
    @State private var displayName: String = P2PNetwork.myPeer.displayName

    var body: some View {
        VStack {
            NavigationStack {
                VStack(spacing: 30) {
                    Text(displayName)
                        .p2pTitleStyle()
                    
                    NavigationLink("이름 설정", destination: ChangeNameView(onNameChanged: { 
                                    displayName = P2PNetwork.myPeer.displayName
                                }))
                                .padding()
                    
                    Button("2인 게임") {
                        P2PNetwork.maxConnectedPeers = 1
                        P2PConstants.setGamePlayerCount(2)
                        P2PNetwork.resetSession()
                        router.currentScreen = .duo
                    }
                    Button("3인 게임") {
                        P2PNetwork.maxConnectedPeers = 2
                        P2PConstants.setGamePlayerCount(3)
                        P2PNetwork.resetSession()
                    }
                    Button("4인 게임") {
                        P2PNetwork.maxConnectedPeers = 3
                        P2PConstants.setGamePlayerCount(4)
                        P2PNetwork.resetSession()
                    }
                }
            }
        }
        .onAppear {
            displayName = P2PNetwork.myPeer.displayName
        }
    }
        

    enum GameType: Hashable, Identifiable {
        var id: Self { self }
        case duo, triple, squad
    }
    
}

#Preview {
    GameStartTab()
        .environmentObject(AppRouter())
}
