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
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    PulsingLoadingView()
                        .frame(height: 200)
                } else {
                    settingsContent
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    private var settingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                headerView
                notificationSettings
                unitSettings
                flightSettings
                dataSettings
                aboutSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SETTINGS")
                .font(.system(size: 20, weight: .ultraLight))
                .foregroundColor(.white)
                .tracking(6)
            
            Text("Customize your experience")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var notificationSettings: some View {
        MinimalSettingsSection(title: "NOTIFICATIONS", icon: "bell") {
            MinimalSettingsToggle(
                title: "Push Notifications",
                subtitle: "Receive flight updates and alerts",
                isOn: $notificationsEnabled
            )
            
            MinimalSettingsToggle(
                title: "Flight Alerts",
                subtitle: "Get notified about flight status changes",
                isOn: $flightAlerts
            )
            
            MinimalSettingsToggle(
                title: "Gate Changes",
                subtitle: "Alerts for gate changes",
                isOn: $gateChanges
            )
            
            MinimalSettingsToggle(
                title: "Delays",
                subtitle: "Notifications for flight delays",
                isOn: $delays
            )
        }
    }
    
    private var unitSettings: some View {
        MinimalSettingsSection(title: "UNITS", icon: "ruler") {
            MinimalSettingsPicker(
                title: "Temperature",
                selection: $temperatureUnit,
                options: ["Celsius", "Fahrenheit"]
            )
            
            MinimalSettingsPicker(
                title: "Distance",
                selection: $distanceUnit,
                options: ["Kilometers", "Miles"]
            )
            
            MinimalSettingsPicker(
                title: "Time Format",
                selection: $timeFormat,
                options: ["12-hour", "24-hour"]
            )
        }
    }
    
    private var flightSettings: some View {
        MinimalSettingsSection(title: "FLIGHT TRACKING", icon: "airplane") {
            MinimalSettingsToggle(
                title: "Offline Mode",
                subtitle: "Use downloaded flight data when offline",
                isOn: $offlineMode
            )
            
            MinimalSettingsToggle(
                title: "Auto Download",
                subtitle: "Automatically download route data for flights",
                isOn: $autoDownload
            )
        }
    }
    
    private var dataSettings: some View {
        MinimalSettingsSection(title: "DATA MANAGEMENT", icon: "externaldrive") {
            MinimalSettingsButton(
                title: "Manage Flight Data",
                subtitle: "View and manage downloaded flight information",
                action: { showingDataManagement = true }
            )
            
            MinimalSettingsButton(
                title: "Clear Cache",
                subtitle: "Free up storage space",
                action: { clearCache() }
            )
            
            MinimalSettingsButton(
                title: "Export Data",
                subtitle: "Export your flight history",
                action: { exportData() }
            )
        }
    }
    
    private var aboutSection: some View {
        MinimalSettingsSection(title: "ABOUT", icon: "info.circle") {
            MinimalSettingsButton(
                title: "Version",
                subtitle: "1.0.0",
                action: { }
            )
            
            MinimalSettingsButton(
                title: "Privacy Policy",
                subtitle: "Learn about data protection",
                action: { }
            )
            
            MinimalSettingsButton(
                title: "Terms of Service",
                subtitle: "Read our terms and conditions",
                action: { }
            )
            
            MinimalSettingsButton(
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

// MARK: - Minimal Settings Components

struct MinimalSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
            }
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}

struct MinimalSettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(0.5)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .white))
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.clear)
    }
}

struct MinimalSettingsPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .tracking(0.5)
            
            Spacer()
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.5)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.clear)
    }
}

struct MinimalSettingsButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(0.5)
                    
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(0.5)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)
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
