//
//  P2PNetwork.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/2/24.
//


import Foundation
import MultipeerConnectivity

public struct P2PConstants {
    public static var networkChannelName = "my-p2p-service"
    public static var loggerEnabled = true // 콘솔 출력(디버깅용) 활성화 여부.
    
    // 내 디바이스의 Peer 정보를 UserDefaults에 저장할 때 쓸 키(key)
    struct UserDefaultsKeys {
        static let myMCPeerID = "com.P2PKit.MyMCPeerIDKey"
        static let myPeerID = "com.P2PKit.MyPeerIDKey"
    }
}

// 내가 연결된 친구(peer) 정보가 바뀔 때 알려주는 알림 역할 프로토콜.
public protocol P2PNetworkPeerDelegate: AnyObject {
    func p2pNetwork(didUpdate peer: Peer) -> Void
    func p2pNetwork(didUpdateHost host: Peer?)
}

// 데이터를 보낼 때 누가 보냈는지, 언제 보냈는지 담는 구조체.
public struct EventInfo: Codable {
    public let senderEntityID: String? // 누가
    public let sendTime: Double // 언제
}

// MARK: - 핵심
public struct P2PNetwork {
    // 실제 연결을 관리하는 세션 객체. 내 정보를 넣어서 새로운 세션을 하나 만듦.
    private static var session = P2PSession(myPeer: Peer.getMyPeer())
    // 연결 상태나 데이터 수신을 감지해서 알려주는 리스너 객체
    private static let sessionListener = P2PNetworkSessionListener()
    //누가 호스트가 될지 결정하는 객체
    private static let hostSelector: P2PHostSelector = {
        let hostSelector = P2PHostSelector()
        // 호스트가 바뀌면 sessionListener한테 바로 알려줌
        hostSelector.onHostUpdateHandler = { host in
            sessionListener.onHostUpdate(host: host)
        }
        return hostSelector
    }()

    // MARK: - Public P2PHostSelector
    // host: 현재 네트워크에서 누가 호스트인지 반환하는 함수
    public static var host: Peer? {
        return hostSelector.host
    }
    // makeMeHost: 나를 호스트로 지정하는 함수
    public static func makeMeHost() {
        hostSelector.makeMeHost()
    }
    
    // MARK: - Public P2PSession Getters
    // myPeer: 내 정보를 반환
    public static var myPeer: Peer {
        return session.myPeer
    }
    
    // 현재 연결된 친구들 목록 출력. soloMode일 땐 가짜 친구 반환.
    public static var connectedPeers: [Peer] {
        return soloMode ? soloModePeers : session.connectedPeers
    }
    
    // 디버깅용: 자기 자신 포함한 모든 피어 목록 출력.
//    public static var allPeers: [Peer] {
//        return session.allPeers
//    }
    
    public static var discoveredPeers: [Peer] {
        return session.discoveredPeers
    }
    
    // 혼자 테스트할 때 사용하는 플래그
    // When true, fake connectedPeers, and disallow sending and receiving.
    public static var soloMode = false
    private static var soloModePeers = {
        // 가짜 플레이어 2명 생성
       return [Peer(MCPeerID(displayName: "Player 1"), id: "Player 1"),
               Peer(MCPeerID(displayName: "Player 2"), id: "Player 2")]
    }()
    
    // MARK: - Public P2PSession Management
    // start: 연결을 시작하는 함수. 앱이 실행되면 무조건 한 번은 호출되어야 한다. 나 지금부터 사람들이랑 연결할래~
    public static func start() {
        if session.delegate == nil {
            P2PNetwork.hostSelector
            session.delegate = sessionListener  // 델리게이트를 설정하고
            session.start() // 세션을 시작함
        }
    }
    
    //:: 내가 만든.. 초대 메시지 보내고, 연결 끊는 함수
    public static func connect(to peerID: MCPeerID) {
        session.invite(peerID)
    }
    public static func disconnect() {
        session.disconnect()
    }
    
    // connectionState: 특정 피어가 연결 상태인지 반환
    public static func connectionState(for peer: MCPeerID) -> MCSessionState? {
        session.connectionState(for: peer)
    }
    
    // resetSession: 세션 이름을 바꿔서 새로 시작하거나, 기존 세션을 닫고 새로 시작하고 싶을 때 사용하는 함수.
    public static func resetSession(displayName: String? = nil) {
        prettyPrint(level: .error, "♻️ Resetting Session!")
        let oldSession = session
        oldSession.disconnect()
        
        // 새로운 PeerID로 새 세션 만들고 시작!
        let newPeerId = MCPeerID(displayName: displayName ?? oldSession.myPeer.displayName)
        let myPeer = Peer.resetMyPeer(with: newPeerId)
        session = P2PSession(myPeer: myPeer)
        session.delegate = sessionListener
        session.start()
    }
    
    // makeBrowserViewController: 애플이 기본으로 제공하는 친구 연결 화면 출력
    public static func makeBrowserViewController() -> MCBrowserViewController {
        return session.makeBrowserViewController()
    }
    
    // MARK: - Peer Delegates
    // 피어 상태 변화 감지하고 싶은 객체 등록
    public static func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        sessionListener.addPeerDelegate(delegate)
    }
    // 피어 상태 변화 감지하고 싶은 객체 삭제
    public static func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        sessionListener.removePeerDelegate(delegate)
    }

    // MARK: - Internal - Send and Receive Events
    // Codable 데이터 전송
    static func send(_ encodable: Encodable, to peers: [MCPeerID] = [], reliable: Bool) {
        guard !soloMode else { return }
        session.send(encodable, to: peers, reliable: reliable)
    }
    // 바이트 데이터 전송
    static func sendData(_ data: Data, to peers: [MCPeerID] = [], reliable: Bool) {
        guard !soloMode else { return }
        session.send(data: data, to: peers, reliable: reliable)
    }
    // 특정 이벤트 이름에 대해 데이터를 수신할 때 실행할 콜백 등록
    static func onReceiveData(eventName: String, _ callback: @escaping DataHandler.Callback) -> DataHandler {
        sessionListener.onReceiveData(eventName: eventName, callback)
    }
}

// 데이터가 왔을 때 실행할 코드(callback)를 보관하는 객체
class DataHandler {
    typealias Callback = (_ data: Data, _ dataAsJson: [String : Any]?, _ fromPeerID: MCPeerID) -> Void
    
    var callback: Callback
    
    init(_ callback: @escaping Callback) {
        self.callback = callback
    }
}

// MARK: - Private
// 연결 상태 알려줄 델리게이트랑 데이터 수신 콜백을 보관하는 약한 참조 배열
private class P2PNetworkSessionListener {
    private var _peerDelegates = WeakArray<P2PNetworkPeerDelegate>()
    private var _dataHandlers = [String: WeakArray<DataHandler>]()
    
    // 호스트가 바뀌면, 등록된 모든 델리게이트에게 알려줌
    fileprivate func onHostUpdate(host: Peer?) {
        for delegate in _peerDelegates {
            delegate?.p2pNetwork(didUpdateHost: host)
        }
    }
    
    // eventName으로 필터링해서 데이터를 받을 수 있음.
    // 예: "MalletDrag"이라는 이름으로 보낸 데이터만 따로 처리
    fileprivate func onReceiveData(eventName: String, _ handleData: @escaping DataHandler.Callback) -> DataHandler {
        let handler = DataHandler(handleData)
        if let handlers = _dataHandlers[eventName] {
            handlers.add(handler)
        } else {
            _dataHandlers[eventName] =  WeakArray<DataHandler>()
            _dataHandlers[eventName]?.add(handler)
        }
        return handler
    }
    
    // 델리게이트 추가
    fileprivate func addPeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        _peerDelegates.add(delegate)
    }
    // 델리게이트 삭제
    fileprivate func removePeerDelegate(_ delegate: P2PNetworkPeerDelegate) {
        _peerDelegates.remove(delegate)
    }
}

// 기본으로 피어 상태 바뀌면 모든 델리게이트에 알려줌
extension P2PNetworkSessionListener: P2PSessionDelegate {
    func p2pSession(_ session: P2PSession, didUpdate peer: Peer) {
        guard !P2PNetwork.soloMode else { return }

        for peerDelegate in _peerDelegates {
            peerDelegate?.p2pNetwork(didUpdate: peer)
        }
    }
    
    func p2pSession(_ session: P2PSession, didReceive data: Data, dataAsJson json: [String : Any]?, from peerID: MCPeerID) {
        guard !P2PNetwork.soloMode else { return }
        
        // 데이터 수신시 eventName가 있으면 그 이름에 해당하는 콜백을 실행함
        if let eventName = json?["eventName"] as? String {
            if let handlers = _dataHandlers[eventName] {
                for handler in handlers {
                    handler?.callback(data, json, peerID)
                }
            }
        }
        
        // 없을 경우 대비해서 “” 빈 문자열 키도 처리
        if let handlers = _dataHandlers[""] {
            for handler in handlers {
                handler?.callback(data, json, peerID)
            }
        }
    }
    
    func p2pSession(_ session: P2PSession, didReceiveInvitationFrom peerID: MCPeerID, handler: @escaping (Bool) -> Void) {
        // 알림 또는 UI 연결을 위해 NotificationCenter 또는 콜백 전달
        NotificationCenter.default.post(
            name: .receivedPeerInvitation,
            object: nil,
            userInfo: [
                "peerID": peerID,
                "handler": handler
            ])
    }
}

extension Notification.Name {
    static let receivedPeerInvitation = Notification.Name("receivedPeerInvitation")
}
