//
//  MapService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreLocation
import MapKit

class MapService: ObservableObject {
    static let shared = MapService()
    
    @Published var offlineRegions: [OfflineRegion] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    
    private let maxOfflineRegions = 750 // Mapbox free tier limit
    
    init() {
        loadOfflineRegions()
    }
    
    
    func downloadOfflineMap(for route: [CLLocationCoordinate2D], withName name: String) async {
        await MainActor.run {
            self.isDownloading = true
            self.downloadProgress = 0.0
        }
        
        let bounds = calculateBounds(for: route)
        
        for i in 0...100 {
            await MainActor.run {
                self.downloadProgress = Double(i) / 100.0
            }
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        }
        
        let region = OfflineRegion(
            id: UUID(),
            name: name,
            bounds: bounds,
            downloadDate: Date(),
            size: estimateSize(for: bounds)
        )
        
        await MainActor.run {
            self.offlineRegions.append(region)
            self.saveOfflineRegions()
            self.isDownloading = false
        }
    }
    
    func downloadFlightPathMap(for flight: SavedFlight) async {
        guard let routeData = flight.routeData else { return }
        
        let name = "\(flight.flightNumber) - \(flight.departure.code) to \(flight.arrival.code)"
        await downloadOfflineMap(for: routeData.waypoints, withName: name)
    }
    
    func downloadAirportMap(for airport: Airport) async {
        let radius: Double = 50000 // 50km radius
        let bounds = createBounds(around: airport.coordinate, radius: radius)
        
        let region = OfflineRegion(
            id: UUID(),
            name: "\(airport.code) - \(airport.name)",
            bounds: bounds,
            downloadDate: Date(),
            size: estimateSize(for: bounds)
        )
        
        await MainActor.run {
            self.offlineRegions.append(region)
            self.saveOfflineRegions()
        }
    }
    
    func deleteOfflineRegion(_ region: OfflineRegion) {
        if let index = offlineRegions.firstIndex(where: { $0.id == region.id }) {
            offlineRegions.remove(at: index)
            saveOfflineRegions()
        }
    }
    
    func getOfflineRegionSize() -> String {
        let totalSize = offlineRegions.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
    
    
    func calculateOptimalRoute(from departure: CLLocationCoordinate2D, to arrival: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        return interpolateGreatCircleRoute(from: departure, to: arrival, segments: 20)
    }
    
    func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) / 1000.0 // Convert to kilometers
    }
    
    
    private func calculateBounds(for route: [CLLocationCoordinate2D]) -> MapBounds {
        guard !route.isEmpty else {
            return MapBounds(
                northEast: CLLocationCoordinate2D(latitude: 90, longitude: 180),
                southWest: CLLocationCoordinate2D(latitude: -90, longitude: -180)
            )
        }
        
        var minLat = route[0].latitude
        var maxLat = route[0].latitude
        var minLon = route[0].longitude
        var maxLon = route[0].longitude
        
        for coordinate in route {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let latPadding = (maxLat - minLat) * 0.1
        let lonPadding = (maxLon - minLon) * 0.1
        
        return MapBounds(
            northEast: CLLocationCoordinate2D(latitude: maxLat + latPadding, longitude: maxLon + lonPadding),
            southWest: CLLocationCoordinate2D(latitude: minLat - latPadding, longitude: minLon - lonPadding)
        )
    }
    
    private func createBounds(around center: CLLocationCoordinate2D, radius: Double) -> MapBounds {
        let latDelta = radius / 111000 // Approximate meters per degree of latitude
        let lonDelta = radius / (111000 * cos(center.latitude * .pi / 180))
        
        return MapBounds(
            northEast: CLLocationCoordinate2D(latitude: center.latitude + latDelta, longitude: center.longitude + lonDelta),
            southWest: CLLocationCoordinate2D(latitude: center.latitude - latDelta, longitude: center.longitude - lonDelta)
        )
    }
    
    private func estimateSize(for bounds: MapBounds) -> Int {
        let latDiff = bounds.northEast.latitude - bounds.southWest.latitude
        let lonDiff = bounds.northEast.longitude - bounds.southWest.longitude
        let area = latDiff * lonDiff
        
        return Int(area * 1_000_000)
    }
    
    private func interpolateGreatCircleRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, segments: Int) -> [CLLocationCoordinate2D] {
        var waypoints: [CLLocationCoordinate2D] = []
        
        let startLat = start.latitude * .pi / 180
        let startLon = start.longitude * .pi / 180
        let endLat = end.latitude * .pi / 180
        let endLon = end.longitude * .pi / 180
        
        let d = 2 * asin(sqrt(pow(sin((startLat - endLat) / 2), 2) + cos(startLat) * cos(endLat) * pow(sin((startLon - endLon) / 2), 2)))
        
        for i in 0...segments {
            let progress = Double(i) / Double(segments)
            
            let a = sin((1 - progress) * d) / sin(d)
            let b = sin(progress * d) / sin(d)
            
            let x = a * cos(startLat) * cos(startLon) + b * cos(endLat) * cos(endLon)
            let y = a * cos(startLat) * sin(startLon) + b * cos(endLat) * sin(endLon)
            let z = a * sin(startLat) + b * sin(endLat)
            
            let resultLat = atan2(z, sqrt(x * x + y * y))
            let resultLon = atan2(y, x)
            
            waypoints.append(CLLocationCoordinate2D(
                latitude: resultLat * 180 / .pi,
                longitude: resultLon * 180 / .pi
            ))
        }
        
        return waypoints
    }
    
    private func saveOfflineRegions() {
        if let data = try? JSONEncoder().encode(offlineRegions) {
            UserDefaults.standard.set(data, forKey: "offline_regions")
        }
    }
    
    private func loadOfflineRegions() {
        if let data = UserDefaults.standard.data(forKey: "offline_regions"),
           let regions = try? JSONDecoder().decode([OfflineRegion].self, from: data) {
            offlineRegions = regions
        }
    }
}


struct OfflineRegion: Codable, Identifiable {
    let id: UUID
    let name: String
    let bounds: MapBounds
    let downloadDate: Date
    let size: Int
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

struct MapBounds: Codable {
    let northEast: CLLocationCoordinate2D
    let southWest: CLLocationCoordinate2D
}
