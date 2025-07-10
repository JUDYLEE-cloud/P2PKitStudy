/*
 Make sure to add in Info.list:
 NSBonjourServices
 item 0: _my-p2p-service._tcp
 item 1: _my-p2p-service._udp
 
 NSLocalNetworkUsageDescription
 This application will use local networking to discover nearby devices. (Or your own custom message)
 
 Every device in the same room should be able to see each other, whether they're on bluetooth or wifi.
 **/

import SwiftUI
import P2PKit

@main
struct P2PKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var router = AppRouter()
    // @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Group {
            TabView() {
                NavigationStack {
                    switch router.currentScreen {
                    case .gameStart:
                        GameStartTab()
                    case .duo:
                        DuoGameView()
                    case .triple:
                        TripleGameView()
                    case .squad:
                        SquadGameView()
                    }
                }
                .tag(0)
                .edgesIgnoringSafeArea(.top)
                .tabItem {
                    Label("Game", systemImage: "gamecontroller.fill")
                }
                
                DebugTab
                    .tag(1)
                    .safeAreaPadding()
                    .tabItem {
                        Label("Debug", systemImage: "newspaper.fill")
                    }
            }
        }
        .tint(.mint)
        .task {
            P2PConstants.networkChannelName = "my-p2p-2p"
            P2PConstants.loggerEnabled = true
        }
    }
        
    var DebugTab: some View {
        VStack(alignment: .leading) {
            PeerListView()
            SyncedCounter()
            SyncedCircles()
            DebugDataView()
            Spacer()
        }.frame(maxWidth: 480)
    }
    
}

#Preview {
    RootView()
}

struct FullscreenWrapperView<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> UIHostingController<ContentWithHomeIndicator> {
        return UIHostingController(rootView: ContentWithHomeIndicator(content: content))
    }

    func updateUIViewController(_ uiViewController: UIHostingController<ContentWithHomeIndicator>, context: Context) {
        uiViewController.rootView = ContentWithHomeIndicator(content: content)
    }

    struct ContentWithHomeIndicator: View {
        let content: Content

        var body: some View {
            content
                .edgesIgnoringSafeArea(.all)
                .background(HomeIndicatorHider())
        }
    }

    class HomeIndicatorHiderViewController: UIViewController {
        override var prefersHomeIndicatorAutoHidden: Bool { true }
    }

    struct HomeIndicatorHider: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> HomeIndicatorHiderViewController {
            HomeIndicatorHiderViewController()
        }

        func updateUIViewController(_ uiViewController: HomeIndicatorHiderViewController, context: Context) { }
    }
}
