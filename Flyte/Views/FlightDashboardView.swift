import SwiftUI
import CoreLocation

struct FlightDashboardView: View {
    @StateObject private var flightManager = FlightManager()
    @State private var selectedFlight: FlightRoute?
    @State private var showingFlightList = false
    @State private var showingSettings = false
    @State private var showingSearch = false
    @State private var showingFlightNumberInput = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if flightManager.isTracking {
                    ActiveFlightView(flightManager: flightManager)
                } else {
                    IdleStateView(
                        showingFlightList: $showingFlightList,
                        showingSettings: $showingSettings,
                        showingSearch: $showingSearch,
                        showingFlightNumberInput: $showingFlightNumberInput,
                        selectedFlight: $selectedFlight,
                        flightManager: flightManager
                    )
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingFlightList) {
            LiveFlightSelectionView(
                selectedFlight: $selectedFlight,
                flightManager: flightManager
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSearch) {
            FlightSearchView()
        }
        .sheet(isPresented: $showingFlightNumberInput) {
            FlightNumberInputView(
                onFlightSelected: { flight in
                    selectedFlight = flight
                    showingFlightNumberInput = false
                    // Start tracking the flight immediately
                    flightManager.startTracking(flight: SavedFlight(
                        flightNumber: flight.flightNumber,
                        departureDate: flight.scheduledDeparture,
                        departureTime: flight.scheduledDeparture,
                        departure: flight.departure,
                        arrival: flight.arrival,
                        airline: flight.airline,
                        aircraft: flight.aircraft
                    ))
                }
            )
        }
    }
}

struct IdleStateView: View {
    @Binding var showingFlightList: Bool
    @Binding var showingSettings: Bool
    @Binding var showingSearch: Bool
    @Binding var showingFlightNumberInput: Bool
    @Binding var selectedFlight: FlightRoute?
    let flightManager: FlightManager
    
    var body: some View {
        VStack(spacing: 60) {
            HStack {
                Button(action: {
                    showingSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            VStack(spacing: 32) {
                Image(systemName: "airplane")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("FLYTE")
                        .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(8)
                    
                    Text("Offline Flight Tracker")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(3)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    showingFlightList = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("START TRACKING")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(2)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white)
                    .cornerRadius(24)
                }
                
                Button(action: {
                    showingSearch = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                        Text("SEARCH FLIGHTS")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(2)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(24)
                }
                
                Button(action: {
                    showingFlightNumberInput = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "textformat.123")
                            .font(.system(size: 12, weight: .medium))
                        Text("FLIGHT NUMBER")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(2)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(24)
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 60)
        }
    }
}

struct ActiveFlightView: View {
    @ObservedObject var flightManager: FlightManager
    
    var body: some View {
        VStack(spacing: 0) {
            FlightHeaderView(flightManager: flightManager)
            
            FlightMapView(flightManager: flightManager)
            
            FlightDetailsView(flightManager: flightManager)
        }
    }
}

struct FlightHeaderView: View {
    @ObservedObject var flightManager: FlightManager
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Button(action: {
                    flightManager.stopTracking()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                }
                
                Spacer()
                
                Color.clear.frame(width: 18)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            if let flight = flightManager.currentTrackingFlight {
                VStack(spacing: 16) {
                    Text("\(flight.airline) \(flight.flightNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(flight.departure.code)
                                .font(.system(size: 20, weight: .ultraLight))
                                .foregroundColor(.white)
                                .tracking(2)
                            Text(flight.departure.city)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 6) {
                            Image(systemName: "airplane")
                                .font(.system(size: 16, weight: .ultraLight))
                                .foregroundColor(.white.opacity(0.4))
                                .rotationEffect(.degrees(45))
                            
                            if let status = flightManager.liveFlightStatus {
                                Text("\(Int(status.progress * 100))%")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                                    .tracking(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(flight.arrival.code)
                                .font(.system(size: 20, weight: .ultraLight))
                                .foregroundColor(.white)
                                .tracking(2)
                            Text(flight.arrival.city)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 24)
    }
}

struct FlightMapView: View {
    @ObservedObject var flightManager: FlightManager
    
    var body: some View {
        MapView(flightManager: flightManager)
    }
}

struct FlightDetailsView: View {
    @ObservedObject var flightManager: FlightManager
    
    var body: some View {
        VStack(spacing: 0) {
            if let status = flightManager.liveFlightStatus {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * status.progress, height: 2)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 32)
                .padding(.top, 32)
                
                VStack(spacing: 32) {
                    HStack(spacing: 16) {
                        MinimalFlightInfoCard(
                            title: "ALTITUDE",
                            value: "\(Int(status.altitude)) ft",
                            icon: "arrow.up"
                        )
                        
                        MinimalFlightInfoCard(
                            title: "SPEED",
                            value: "\(Int(status.speed)) mph",
                            icon: "speedometer"
                        )
                    }
                    
                    HStack(spacing: 16) {
                        MinimalFlightInfoCard(
                            title: "TIME LEFT",
                            value: formatTime(status.estimatedTimeRemaining),
                            icon: "clock"
                        )
                        
                        MinimalFlightInfoCard(
                            title: "DISTANCE",
                            value: "\(Int(status.distanceRemaining)) mi",
                            icon: "map"
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)
            }
            
            Spacer()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct MinimalFlightInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.8))
                .tracking(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    FlightDashboardView()
}
