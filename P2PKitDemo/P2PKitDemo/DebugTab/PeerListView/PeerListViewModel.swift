//
//  PeerListViewModel.swift
//  P2PKitDemo
//
//  Created by 이주현 on 7/8/25.
//

import Foundation
import P2PKit
import MultipeerConnectivity

class PeerListViewModel: ObservableObject {
    @Published var peerList = [Peer]()
    @Published var host: Peer? = nil
        
    init() {
        P2PNetwork.addPeerDelegate(self) // 이 뷰모델을 delegate로 등록해서 P2P 이벤트 받을 수 있게 함
        p2pNetwork(didUpdate: P2PNetwork.myPeer) // 자기 자신의 정보를 한 번 초기 업데이트
        p2pNetwork(didUpdateHost: P2PNetwork.host) // 자기 자신의 정보를 한 번 초기 업데이트
    }
    
    deinit {
        P2PNetwork.removePeerDelegate(self) // 뷰모델이 없어지면 델리게이트 제거
    }
    
    // 1. 이름 변경 함수
    func changeName() {
        let randomAnimal = Array("🦊🐯🐹🐶🐸🐵🐮🦄🐷🐰🐻").randomElement()!
        P2PNetwork.resetSession(displayName: "\(randomAnimal) \(UIDevice.current.name)")
    }
    // 2. 세션 초기화
    func resetSession() {
        P2PNetwork.resetSession(displayName: newDisplayName(from: P2PNetwork.myPeer.displayName))
    }
    // 3. 이름 재 정의
    private func newDisplayName(from oldName: String) -> String {
        if let result = try? /\s<<(\d+)>>/.firstMatch(in: oldName), let count = Int(result.1)  {
            return oldName.replacing(/\s<<(\d+)>>/, with: "") + " <<\(count + 1)>>"
        } else {
            return oldName + " <<1>>"
        }
    }
}

extension PeerListViewModel: P2PNetworkPeerDelegate {
    
    func p2pNetwork(didUpdateHost host: Peer?) {
        DispatchQueue.main.async { [weak self] in
            self?.host = host
        }
    }
    
    // 나 자신은 제외하고 나머지를 peerList로 설정
    // 피어 하나가 업데이트될 때마다 실행됨
    func p2pNetwork(didUpdate peer: Peer) {
        DispatchQueue.main.async { [weak self] in
            self?.peerList = P2PNetwork.discoveredPeers.filter { peer in
                peer.peerID != P2PNetwork.myPeer.peerID
            }
        }
    }
    
}

public extension Notification.Name {
    static let receivedPeerInvitation = Notification.Name("receivedPeerInvitation")
}
