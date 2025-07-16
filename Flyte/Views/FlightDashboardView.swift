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
        VStack(spacing: 40) {
            HStack {
                Button(action: {
                    showingSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 20) {
                Image(systemName: "airplane")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("FLYTE")
                    .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                
                Text("Offline Flight Tracker")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    showingFlightList = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Start Tracking")
                            .font(.system(size: 18, weight: .medium))
                            .tracking(1)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(28)
                }
                
                Button(action: {
                    showingSearch = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                        Text("Search Flights")
                            .font(.system(size: 16, weight: .medium))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(24)
                }
                
                Button(action: {
                    showingFlightNumberInput = true
                }) {
                    HStack {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Enter Flight Number")
                            .font(.system(size: 16, weight: .medium))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(24)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
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
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    flightManager.stopTracking()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("LIVE TRACKING")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .tracking(2)
                
                Spacer()
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .opacity(0.8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            if let flight = flightManager.currentTrackingFlight {
                VStack(spacing: 12) {
                    Text("\(flight.airline) \(flight.flightNumber)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flight.departure.code)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text(flight.departure.city)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Image(systemName: "airplane")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            if let status = flightManager.liveFlightStatus {
                                Text("\(Int(status.progress * 100))%")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(flight.arrival.code)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text(flight.arrival.city)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
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
                Rectangle()
                    .fill(Color.white)
                    .frame(height: status.progress * UIScreen.main.bounds.width)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .frame(height: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        FlightInfoCard(
                            title: "ALTITUDE",
                            value: "\(Int(status.altitude)) ft",
                            icon: "arrow.up"
                        )
                        
                        FlightInfoCard(
                            title: "SPEED",
                            value: "\(Int(status.speed)) mph",
                            icon: "speedometer"
                        )
                    }
                    
                    HStack(spacing: 20) {
                        FlightInfoCard(
                            title: "TIME LEFT",
                            value: formatTime(status.estimatedTimeRemaining),
                            icon: "clock"
                        )
                        
                        FlightInfoCard(
                            title: "DISTANCE",
                            value: "\(Int(status.distanceRemaining)) mi",
                            icon: "ruler"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
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

struct FlightInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    FlightDashboardView()
}
