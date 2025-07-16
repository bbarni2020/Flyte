import SwiftUI
import MapKit

struct OfflineModeView: View {
    @StateObject private var flightManager = FlightManager()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if isLoading {
                        PulsingLoadingView()
                            .frame(height: 200)
                    } else if let trackingFlight = flightManager.currentTrackingFlight {
                        trackingContent(for: trackingFlight)
                    } else {
                        noTrackingView
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if flightManager.currentTrackingFlight != nil {
                startLoading()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRACK")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(.white)
                    .tracking(4)
                
                Text("Offline Mode")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
            }
            
            Spacer()
            
            Button(action: { flightManager.toggleOfflineMode() }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(flightManager.isOfflineMode ? Color.white.opacity(0.3) : Color.white)
                        .frame(width: 4, height: 4)
                    Text(flightManager.isOfflineMode ? "OFFLINE" : "ONLINE")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(flightManager.isOfflineMode ? .white.opacity(0.4) : .white.opacity(0.8))
                        .tracking(1)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
    
    private var noTrackingView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No Active Flight")
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Text("Start tracking a flight from your home screen to see live updates here")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func trackingContent(for flight: SavedFlight) -> some View {
        VStack(spacing: 0) {
            flightMapView(for: flight)
                .frame(height: 300)
                .cornerRadius(16)
                .padding(.horizontal, 16)
            
            flightStatusCard(for: flight)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            Spacer()
            
            controlButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
        }
    }
    
    private func flightMapView(for flight: SavedFlight) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    VStack {
                        if let liveStatus = flightManager.liveFlightStatus {
                            LiveFlightMapView(
                                departure: flight.departure,
                                arrival: flight.arrival,
                                currentLocation: liveStatus.currentLocation,
                                progress: liveStatus.progress
                            )
                        } else {
                            StaticFlightMapView(
                                departure: flight.departure,
                                arrival: flight.arrival
                            )
                        }
                    }
                )
        }
    }
    
    private func flightStatusCard(for flight: SavedFlight) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.flightNumber)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(flight.airline)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(flight.status.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(flight.status.color))
                }
            }
            
            if let liveStatus = flightManager.liveFlightStatus {
                liveStatusDetails(liveStatus)
            }
            
            progressBar(for: flight)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func liveStatusDetails(_ status: LiveFlightStatus) -> some View {
        VStack(spacing: 12) {
            HStack {
                StatusInfoView(
                    title: "Altitude",
                    value: String(format: "%.0f ft", status.altitude),
                    icon: "arrow.up"
                )
                
                Spacer()
                
                StatusInfoView(
                    title: "Speed",
                    value: String(format: "%.0f mph", status.speed),
                    icon: "speedometer"
                )
                
                Spacer()
                
                StatusInfoView(
                    title: "Location",
                    value: status.currentCountry,
                    icon: "location"
                )
            }
            
            HStack {
                StatusInfoView(
                    title: "Time Remaining",
                    value: formatTimeInterval(status.estimatedTimeRemaining),
                    icon: "clock"
                )
                
                Spacer()
                
                StatusInfoView(
                    title: "Distance Left",
                    value: String(format: "%.0f mi", status.distanceRemaining),
                    icon: "map"
                )
            }
        }
    }
    
    private func progressBar(for flight: SavedFlight) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(flight.departure.code)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(flight.arrival.code)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (flightManager.liveFlightStatus?.progress ?? 0.0), height: 4)
                        .cornerRadius(2)
                        .animation(.linear(duration: 1.0), value: flightManager.liveFlightStatus?.progress)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button(action: { flightManager.stopTracking() }) {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 12, weight: .medium))
                    Text("STOP TRACKING")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(20)
            }
            
            Button(action: { flightManager.toggleOfflineMode() }) {
                HStack(spacing: 6) {
                    Image(systemName: flightManager.isOfflineMode ? "wifi" : "wifi.slash")
                        .font(.system(size: 12, weight: .medium))
                    Text(flightManager.isOfflineMode ? "GO ONLINE" : "GO OFFLINE")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(20)
            }
        }
    }
    
    private func startLoading() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct StatusInfoView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LiveFlightMapView: View {
    let departure: Airport
    let arrival: Airport
    let currentLocation: CLLocationCoordinate2D
    let progress: Double
    
    @State private var region: MKCoordinateRegion
    
    init(departure: Airport, arrival: Airport, currentLocation: CLLocationCoordinate2D, progress: Double) {
        self.departure = departure
        self.arrival = arrival
        self.currentLocation = currentLocation
        self.progress = progress
        
        let centerLatitude = (departure.coordinate.latitude + arrival.coordinate.latitude) / 2
        let centerLongitude = (departure.coordinate.longitude + arrival.coordinate.longitude) / 2
        let latitudeDelta = abs(departure.coordinate.latitude - arrival.coordinate.latitude) * 1.5
        let longitudeDelta = abs(departure.coordinate.longitude - arrival.coordinate.longitude) * 1.5
        
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: .constant(region), annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack {
                        Image(systemName: annotation.icon)
                            .font(.title2)
                            .foregroundColor(annotation.color)
                        
                        Text(annotation.title)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
            }
            .disabled(true)
        }
        .cornerRadius(16)
    }
    
    private var annotations: [FlightMapAnnotation] {
        [
            FlightMapAnnotation(
                coordinate: departure.coordinate,
                title: departure.code,
                icon: "airplane.departure",
                color: .blue
            ),
            FlightMapAnnotation(
                coordinate: arrival.coordinate,
                title: arrival.code,
                icon: "airplane.arrival",
                color: .green
            ),
            FlightMapAnnotation(
                coordinate: currentLocation,
                title: "Current",
                icon: "airplane",
                color: .red
            )
        ]
    }
}

struct StaticFlightMapView: View {
    let departure: Airport
    let arrival: Airport
    
    @State private var region: MKCoordinateRegion
    
    init(departure: Airport, arrival: Airport) {
        self.departure = departure
        self.arrival = arrival
        
        let centerLatitude = (departure.coordinate.latitude + arrival.coordinate.latitude) / 2
        let centerLongitude = (departure.coordinate.longitude + arrival.coordinate.longitude) / 2
        let latitudeDelta = abs(departure.coordinate.latitude - arrival.coordinate.latitude) * 1.5
        let longitudeDelta = abs(departure.coordinate.longitude - arrival.coordinate.longitude) * 1.5
        
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                VStack {
                    Image(systemName: annotation.icon)
                        .font(.title2)
                        .foregroundColor(annotation.color)
                    
                    Text(annotation.title)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                }
            }
        }
        .disabled(true)
        .cornerRadius(16)
    }
    
    private var annotations: [FlightMapAnnotation] {
        [
            FlightMapAnnotation(
                coordinate: departure.coordinate,
                title: departure.code,
                icon: "airplane.departure",
                color: .blue
            ),
            FlightMapAnnotation(
                coordinate: arrival.coordinate,
                title: arrival.code,
                icon: "airplane.arrival",
                color: .green
            )
        ]
    }
}

struct FlightMapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let icon: String
    let color: Color
}
