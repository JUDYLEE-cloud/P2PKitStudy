//
//  2 GameResultView.swift
//  P2PKitDemo
//
//  Created by 이주현 on 7/10/25.
//

import SwiftUI
import P2PKit

struct GameResultView: View {
    let result: GameResult
    @EnvironmentObject var router: AppRouter

    var body: some View {
        VStack {
            Text(resultText)
                .font(.largeTitle)
                .padding()
            
            Button("다시 시작") {
                // 이건 뭘 선택하냐에 따라 바뀌어야 함
                P2PNetwork.maxConnectedPeers = 1
                P2PConstants.setGamePlayerCount(2)
                
                router.currentScreen = .none
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        router.currentScreen = .duo
                    }
            }
            Button("나가기") {
                router.currentScreen = .gameStart
            }
        }
        .task {
            P2PNetwork.outSession()
            P2PNetwork.removeAllDelegates()
        }
    }

    private var resultText: String {
        switch result {
        case .winner(let name):
            return "\(name) 승리!"
        case .draw:
            return "무승부"
        }
    }
}
