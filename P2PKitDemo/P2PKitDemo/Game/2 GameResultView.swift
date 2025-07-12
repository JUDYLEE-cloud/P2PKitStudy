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
//                P2PNetwork.outSession()
//                P2PNetwork.removeAllDelegates()
                // router.currentScreen = .gameStart
                router.currentScreen = .duo
            }
            Button("나가기") {
//                P2PNetwork.outSession()
//                P2PNetwork.removeAllDelegates()
                router.currentScreen = .gameStart
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                P2PNetwork.outSession()
                P2PNetwork.removeAllDelegates()
            }
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
