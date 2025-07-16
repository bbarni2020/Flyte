import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useMetricUnits") private var useMetricUnits = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("trackingInterval") private var trackingInterval = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            unitsSection
                            notificationsSection
                            trackingSection
                            aboutSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("SETTINGS")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UNITS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            SettingsToggle(
                title: "Metric Units",
                subtitle: "Use kilometers and meters",
                isOn: $useMetricUnits
            )
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NOTIFICATIONS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            SettingsToggle(
                title: "Flight Updates",
                subtitle: "Get notified about flight progress",
                isOn: $showNotifications
            )
        }
    }
    
    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TRACKING")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Update Interval")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(trackingInterval))s")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Slider(value: $trackingInterval, in: 0.5...5.0, step: 0.5)
                    .accentColor(.white)
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ABOUT")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            VStack(spacing: 12) {
                SettingsRow(title: "Version", value: "1.0.0")
                SettingsRow(title: "Build", value: "2025.07.16")
                SettingsRow(title: "Developer", value: "Balogh Barnabás")
            }
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.white)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    SettingsView()
}
