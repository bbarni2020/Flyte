//
//  OfflineMapOptionsView.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import SwiftUI

struct OfflineMapOptionsView: View {
    @ObservedObject var flightManager: FlightManager
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var mapService = MapService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    Picker("Options", selection: $selectedTab) {
                        Text("Download").tag(0)
                        Text("Manage").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    if selectedTab == 0 {
                        downloadOptionsView
                    } else {
                        manageOfflineView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text("Offline Maps")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
    
    private var downloadOptionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let flight = flightManager.currentTrackingFlight {
                    currentFlightSection(flight: flight)
                }
                
                flightPathSection
                airportSection
                usageSection
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var manageOfflineView: some View {
        ScrollView {
            VStack(spacing: 24) {
                usageOverview
                offlineRegionsList
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func currentFlightSection(flight: SavedFlight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("CURRENT FLIGHT")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flight.flightNumber)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("\(flight.departure.code) → \(flight.arrival.code)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            downloadFlightMap(flight: flight)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 12, weight: .medium))
                                
                                Text("Download")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(mapService.isDownloading)
                    }
                    
                    if mapService.isDownloading {
                        ProgressView(value: mapService.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    private var flightPathSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("FLIGHT PATHS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(spacing: 12) {
                    ForEach(flightManager.savedFlights.prefix(3)) { flight in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(flight.flightNumber)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(flight.departure.code) → \(flight.arrival.code)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                downloadFlightMap(flight: flight)
                            }) {
                                Image(systemName: flight.isDownloaded ? "checkmark.circle.fill" : "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(flight.isDownloaded ? .green : .white.opacity(0.6))
                            }
                            .disabled(mapService.isDownloading || flight.isDownloaded)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    private var airportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "building.2")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("AIRPORT TERMINALS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Download detailed terminal maps for your departure and arrival airports")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button(action: {
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12, weight: .medium))
                            
                            Text("Download Airport Maps")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("USAGE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Downloaded Regions:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(mapService.offlineRegions.count)/750")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    ProgressView(value: Double(mapService.offlineRegions.count), total: 750)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.6)))
                    
                    HStack {
                        Text("Storage Used:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(mapService.getOfflineRegionSize())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    private var usageOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("OVERVIEW")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(mapService.offlineRegions.count)")
                                .font(.system(size: 20, weight: .ultraLight))
                                .foregroundColor(.white)
                            
                            Text("Downloaded Regions")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(mapService.getOfflineRegionSize())
                                .font(.system(size: 20, weight: .ultraLight))
                                .foregroundColor(.white)
                            
                            Text("Storage Used")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    ProgressView(value: Double(mapService.offlineRegions.count), total: 750)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.6)))
                    
                    Text("Free tier allows up to 750 offline regions")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    private var offlineRegionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("DOWNLOADED REGIONS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                if mapService.offlineRegions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 24, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No offline regions downloaded")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 8) {
                        ForEach(mapService.offlineRegions) { region in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(region.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Downloaded \(region.downloadDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(region.formattedSize)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Button(action: {
                                        mapService.deleteOfflineRegion(region)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.red.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func downloadFlightMap(flight: SavedFlight) {
        Task {
            await mapService.downloadFlightPathMap(for: flight)
        }
    }
}

#Preview {
    OfflineMapOptionsView(flightManager: FlightManager())
}
