import SwiftUI
import CoreLocation
import MapKit

struct MapView: View {
    @ObservedObject var flightManager: FlightManager
    @State private var showingFullMap = false
    @State private var showingOfflineMapOptions = false
    @State private var currentLocationName: String = ""
    
    @ObservedObject private var mapService = MapService.shared
    @ObservedObject private var geocodeService = GeocodeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            mapHeaderView
            
            Button(action: {
                showingFullMap = true
            }) {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    if let progress = flightManager.flightProgress,
                       let flight = flightManager.currentTrackingFlight {
                        VStack(spacing: 16) {
                            routeVisualization(flight: flight, progress: progress)
                            locationInfo(progress: progress)
                        }
                    } else if let status = flightManager.liveFlightStatus,
                             let flight = flightManager.currentTrackingFlight {
                        VStack(spacing: 16) {
                            routeVisualizationLegacy(flight: flight, status: status)
                            locationInfoLegacy(status: status)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 32, weight: .ultraLight))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("TAP TO VIEW MAP")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(3)
                        }
                    }
                }
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingFullMap) {
            FullMapView(flightManager: flightManager)
        }
        .sheet(isPresented: $showingOfflineMapOptions) {
            OfflineMapOptionsView(flightManager: flightManager)
        }
    }
    
    private var mapHeaderView: some View {
        HStack {
            Text("FLIGHT PATH")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
            
            Spacer()
            
            if flightManager.isTracking {
                HStack(spacing: 8) {
                    if flightManager.isOfflineMode {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text("OFFLINE")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange)
                                .tracking(1)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                            
                            Text("LIVE")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                        }
                    }
                    
                    Button(action: {
                        showingOfflineMapOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private func routeVisualization(flight: SavedFlight, progress: FlightProgress) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                Text(flight.departure.code)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 160 * progress.progressPercentage, height: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Spacer()
                    
                    Image(systemName: progress.isOnGround ? "airplane.departure" : "airplane")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(progress.heading))
                        .offset(x: -80 + (160 * progress.progressPercentage))
                    
                    Spacer()
                }
            }
            .frame(width: 160)
            
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text(flight.arrival.code)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func locationInfo(progress: FlightProgress) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(progress.currentLocationName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ALTITUDE")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(1)
                    
                    Text("\(Int(progress.altitude)) ft")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.5)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPEED")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(1)
                    
                    Text("\(Int(progress.speed * 3.6)) km/h")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.5)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROGRESS")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(1)
                    
                    Text("\(Int(progress.progressPercentage * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.5)
                }
            }
        }
    }
    
    private func routeVisualizationLegacy(flight: SavedFlight, status: LiveFlightStatus) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                Text(flight.departure.code)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 160 * status.progress, height: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Spacer()
                    
                    Image(systemName: "airplane")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(45))
                        .offset(x: -80 + (160 * status.progress))
                    
                    Spacer()
                }
            }
            .frame(width: 160)
            
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text(flight.arrival.code)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func locationInfoLegacy(status: LiveFlightStatus) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(status.currentCountry)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
            }
            
            Text("\(status.currentLocation.latitude, specifier: "%.4f")°, \(status.currentLocation.longitude, specifier: "%.4f")°")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1)
        }
    }
}

struct FullMapView: View {
    @ObservedObject var flightManager: FlightManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        if let status = flightManager.liveFlightStatus,
                           let flight = flightManager.currentTrackingFlight {
                            VStack(spacing: 32) {
                                Text("FLIGHT MAP")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(3)
                                
                                VStack(spacing: 24) {
                                    Text("CURRENT POSITION")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                        .tracking(2)
                                    
                                    Text(status.currentCountry)
                                        .font(.system(size: 20, weight: .ultraLight))
                                        .foregroundColor(.white)
                                        .tracking(2)
                                    
                                    Text("\(status.currentLocation.latitude, specifier: "%.6f")°, \(status.currentLocation.longitude, specifier: "%.6f")°")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                        .tracking(1)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 16) {
                                    Text("PROGRESS")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                        .tracking(2)
                                    
                                    HStack {
                                        Text(flight.departure.code)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                            .tracking(1)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(status.progress * 100))%")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.4))
                                            .tracking(1)
                                        
                                        Spacer()
                                        
                                        Text(flight.arrival.code)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                            .tracking(1)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 1)
                                            
                                            Rectangle()
                                                .fill(Color.white)
                                                .frame(width: geometry.size.width * status.progress, height: 1)
                                        }
                                    }
                                    .frame(height: 1)
                                }
                                .padding(.horizontal, 48)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
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
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text("MAP")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .tracking(4)
            
            Spacer()
            
            Color.clear.frame(width: 18)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
}

#Preview {
    MapView(flightManager: FlightManager())
}
