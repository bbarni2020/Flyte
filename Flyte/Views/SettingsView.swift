import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("offlineMode") private var offlineMode = false
    @AppStorage("temperatureUnit") private var temperatureUnit = "Celsius"
    @AppStorage("distanceUnit") private var distanceUnit = "Kilometers"
    @AppStorage("timeFormat") private var timeFormat = "24-hour"
    @AppStorage("autoDownload") private var autoDownload = false
    @AppStorage("flightAlerts") private var flightAlerts = true
    @AppStorage("gateChanges") private var gateChanges = true
    @AppStorage("delays") private var delays = true
    
    @State private var showingAbout = false
    @State private var showingDataManagement = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    PulsingLoadingView()
                        .frame(height: 200)
                } else {
                    settingsContent
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var settingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                notificationSettings
                unitSettings
                flightSettings
                dataSettings
                aboutSection
            }
            .padding()
        }
    }
    
    private var notificationSettings: some View {
        SettingsSection(title: "Notifications", icon: "bell") {
            SettingsToggle(
                title: "Push Notifications",
                subtitle: "Receive flight updates and alerts",
                isOn: $notificationsEnabled
            )
            
            SettingsToggle(
                title: "Flight Alerts",
                subtitle: "Get notified about flight status changes",
                isOn: $flightAlerts
            )
            
            SettingsToggle(
                title: "Gate Changes",
                subtitle: "Alerts for gate changes",
                isOn: $gateChanges
            )
            
            SettingsToggle(
                title: "Delays",
                subtitle: "Notifications for flight delays",
                isOn: $delays
            )
        }
    }
    
    private var unitSettings: some View {
        SettingsSection(title: "Units", icon: "ruler") {
            SettingsPicker(
                title: "Temperature",
                selection: $temperatureUnit,
                options: ["Celsius", "Fahrenheit"]
            )
            
            SettingsPicker(
                title: "Distance",
                selection: $distanceUnit,
                options: ["Kilometers", "Miles"]
            )
            
            SettingsPicker(
                title: "Time Format",
                selection: $timeFormat,
                options: ["12-hour", "24-hour"]
            )
        }
    }
    
    private var flightSettings: some View {
        SettingsSection(title: "Flight Tracking", icon: "airplane") {
            SettingsToggle(
                title: "Offline Mode",
                subtitle: "Use downloaded flight data when offline",
                isOn: $offlineMode
            )
            
            SettingsToggle(
                title: "Auto Download",
                subtitle: "Automatically download route data for flights",
                isOn: $autoDownload
            )
        }
    }
    
    private var dataSettings: some View {
        SettingsSection(title: "Data Management", icon: "externaldrive") {
            SettingsButton(
                title: "Manage Flight Data",
                subtitle: "View and manage downloaded flight information",
                action: { showingDataManagement = true }
            )
            
            SettingsButton(
                title: "Clear Cache",
                subtitle: "Free up storage space",
                action: { clearCache() }
            )
            
            SettingsButton(
                title: "Export Data",
                subtitle: "Export your flight history",
                action: { exportData() }
            )
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            SettingsButton(
                title: "Version",
                subtitle: "1.0.0",
                action: { }
            )
            
            SettingsButton(
                title: "Privacy Policy",
                subtitle: "Learn about data protection",
                action: { }
            )
            
            SettingsButton(
                title: "Terms of Service",
                subtitle: "Read our terms and conditions",
                action: { }
            )
            
            SettingsButton(
                title: "Contact Support",
                subtitle: "Get help with the app",
                action: { }
            )
        }
    }
    
    private func clearCache() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
    
    private func exportData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
}

struct SettingsPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
}

struct SettingsButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
        }
    }
}
