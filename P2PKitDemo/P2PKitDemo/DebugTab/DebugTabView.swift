//
//  DebugTabView.swift
//  P2PKitDemo
//
//  Created by 이주현 on 7/8/25.
//

import SwiftUI
import P2PKit
import MultipeerConnectivity

struct DebugTabView: View {
    @State private var showInvitationAlert = false
    @State private var pendingInvitation: (peerID: MCPeerID, handler: (Bool) -> Void)? = nil
    @State private var invitationTimer = 25
    @State private var invitationCountdownTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            
            VStack(alignment: .leading) {
                PeerListView()
                SyncedCounter()
                // SyncedCircles()
                // DebugDataView()
                Spacer()
            }
            
            // 커스텀 알람
            ZStack {
                if showInvitationAlert {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("\(pendingInvitation?.peerID.displayName ?? "알 수 없음")님이 연결을 요청했습니다.")
                            .font(.headline)
                        Text("\(invitationTimer)초 안에 응답해 주세요.")
                            .font(.subheadline)
                        
                        HStack {
                            Button("수락") {
                                invitationCountdownTimer?.invalidate()
                                pendingInvitation?.handler(true)
                                pendingInvitation = nil
                                showInvitationAlert = false
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("거절") {
                                invitationCountdownTimer?.invalidate()
                                pendingInvitation?.handler(false)
                                pendingInvitation = nil
                                showInvitationAlert = false
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .frame(maxWidth: 300)
                }
                
            }
            
        }
        .onReceive(NotificationCenter.default.publisher(for: .receivedPeerInvitation)) { notification in
            guard
                let userInfo = notification.userInfo,
                let peerID = userInfo["peerID"] as? MCPeerID,
                let handler = userInfo["handler"] as? (Bool) -> Void
            else {
                return
            }
            pendingInvitation = (peerID: peerID, handler: handler)
            showInvitationAlert = true
            invitationTimer = 25
            
            invitationCountdownTimer?.invalidate()  // 기존 타이머 중복 방지
            invitationCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                DispatchQueue.main.async {
                    invitationTimer -= 1
                    if invitationTimer <= 0 {
                        timer.invalidate()
                        invitationCountdownTimer = nil
                        showInvitationAlert = false
                        pendingInvitation?.handler(false)
                        pendingInvitation = nil
                    }
                }
            }
            
        }
    }
}

#Preview {
    DebugTabView()
}
