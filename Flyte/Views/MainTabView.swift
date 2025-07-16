import SwiftUI

struct MainTabView: View {
    @StateObject private var flightManager = FlightManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            OfflineModeView()
                .tabItem {
                    Image(systemName: "airplane")
                    Text("Track")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .environmentObject(flightManager)
    }
}
