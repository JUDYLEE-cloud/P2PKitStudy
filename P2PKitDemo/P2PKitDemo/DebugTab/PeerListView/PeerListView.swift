//
//  PeerListView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/24/24.
//

import SwiftUI
import P2PKit
import MultipeerConnectivity

struct PeerListView: View {
    @StateObject var model = PeerListViewModel()
    @State private var connectedPeerIDs: Set<MCPeerID> = []

    
    var body: some View {
        // 본문 내용
        VStack(alignment: .leading) {
            Text("Me").p2pTitleStyle()
            Text(peerSummaryText(P2PNetwork.myPeer))
            HStack {
                Button("Change Name") {
                    model.changeName()
                }
                Button("Reset Session") {
                    model.resetSession()
                }
            }.p2pSecondaryButtonStyle()
            
            Button("Make Me Host 🚀") {
                P2PNetwork.makeMeHost()
            }.p2pSecondaryButtonStyle()
            
            Text("Found Players").p2pTitleStyle()
            Text("총 연결된 사람 수: \(P2PNetwork.connectedPeers.count)")
            VStack(alignment: .leading, spacing: 10) {
                if model.peerList.isEmpty {
                    ProgressView()
                } else {
                    
                    ForEach(model.peerList, id: \.peerID) { peer in
                        let connectionState = P2PNetwork.connectionState(for: peer.peerID)
                        let connectionStateStr = connectionState != nil ? connectionState!.debugDescription : "No Session"
                        Text("\(peerSummaryText(peer)): \(connectionStateStr)")
                    }
                    
                    ForEach(model.peerList, id: \.peerID) { peer in
                        HStack {
                            Text(peer.displayName)
                            
                            Button("연결") {
                                P2PNetwork.connect(to: peer.peerID)
                                connectedPeerIDs.insert(peer.peerID)
                            }
                            .disabled(P2PNetwork.connectedPeers.count >= 1)
                            
                            if connectedPeerIDs.contains(peer.peerID) {
                                Button("연결 끊기") {
                                    P2PNetwork.disconnect()
                                    connectedPeerIDs.remove(peer.peerID)
                                }
                            }
                            
                        }
                    }
                    
                }
            }
        }
        
    }
    
    private func peerSummaryText(_ peer: Peer) -> String {
        let isHostString = model.host?.peerID == peer.peerID ? " 🚀" : ""
        return peer.displayName + isHostString
    }
}

#Preview {
    PeerListView()
}
