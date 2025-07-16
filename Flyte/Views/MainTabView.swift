import SwiftUI

struct MainTabView: View {
    @StateObject private var flightManager = FlightManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            OfflineModeView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "airplane.circle.fill" : "airplane.circle")
                    Text("Track")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "gear.circle.fill" : "gear.circle")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.white)
        .preferredColorScheme(.dark)
        .environmentObject(flightManager)
    }
}
