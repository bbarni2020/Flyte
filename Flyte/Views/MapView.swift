import SwiftUI
import CoreLocation

struct MapView: View {
    @ObservedObject var flightTracker: FlightTracker
    @State private var showingFullMap = false
    
    var body: some View {
        VStack(spacing: 0) {
            mapHeaderView
            
            Button(action: {
                showingFullMap = true
            }) {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 250)
                    
                    if let status = flightTracker.flightStatus,
                       let flight = flightTracker.currentFlight {
                        VStack(spacing: 16) {
                            routeVisualization(flight: flight, status: status)
                            locationInfo(status: status)
                        }
                    } else {
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("TAP TO VIEW MAP")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(2)
                        }
                    }
                }
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingFullMap) {
            FullMapView(flightTracker: flightTracker)
        }
    }
    
    private var mapHeaderView: some View {
        HStack {
            Text("FLIGHT PATH")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            Spacer()
            
            if flightTracker.isTracking {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                        .tracking(1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private func routeVisualization(flight: FlightRoute, status: FlightStatus) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                Text(flight.departure.code)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 2)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 200 * status.progress, height: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Spacer()
                    
                    Image(systemName: "airplane")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(45))
                        .offset(x: -100 + (200 * status.progress))
                    
                    Spacer()
                }
            }
            .frame(width: 200)
            
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 8, height: 8)
                Text(flight.arrival.code)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func locationInfo(status: FlightStatus) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(status.currentCountry)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("\(status.currentLocation.latitude, specifier: "%.4f")°, \(status.currentLocation.longitude, specifier: "%.4f")°")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
        }
    }
}

struct FullMapView: View {
    @ObservedObject var flightTracker: FlightTracker
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                        
                        if let status = flightTracker.flightStatus,
                           let flight = flightTracker.currentFlight {
                            VStack(spacing: 20) {
                                Text("DETAILED MAP VIEW")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .tracking(2)
                                
                                VStack(spacing: 16) {
                                    Text("Current Position")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(status.currentCountry)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("\(status.currentLocation.latitude, specifier: "%.6f")°, \(status.currentLocation.longitude, specifier: "%.6f")°")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .tracking(1)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 12) {
                                    Text("Flight Progress")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack {
                                        Text(flight.departure.code)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(status.progress * 100))%")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        Text(flight.arrival.code)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    ProgressView(value: status.progress)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .scaleEffect(y: 2)
                                        .tint(.white)
                                }
                                .padding(.horizontal, 40)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
            
            Text("FLIGHT MAP")
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
}

#Preview {
    MapView(flightTracker: FlightTracker())
}
