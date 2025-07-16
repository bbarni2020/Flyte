//
//  OpenSkyService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreLocation
import Combine

class OpenSkyService: ObservableObject {
    static let shared = OpenSkyService()
    
    private let baseURL = "https://opensky-network.org/api"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    private var trackingTimer: Timer?
    
    @Published var currentStates: [OpenSkyState] = []
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: Error?
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "opensky_states_cache"
    private let lastUpdateKey = "opensky_last_update"
    
    init() {
        loadCachedStates()
    }
    
    
    func startRealTimeTracking(updateInterval: TimeInterval = 45) {
        stopTracking()
        
        Task {
            await fetchAllStates()
        }
        
        trackingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchAllStates()
            }
        }
    }
    
    func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    func fetchAllStates() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        guard let url = URL(string: "\(baseURL)/states/all") else {
            await MainActor.run {
                self.error = URLError(.badURL)
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.error = URLError(.badServerResponse)
                    self.isLoading = false
                }
                return
            }
            
            let openSkyResponse = try JSONDecoder().decode(OpenSkyResponse.self, from: data)
            let states = parseStates(from: openSkyResponse)
            
            await MainActor.run {
                self.currentStates = states
                self.lastUpdateTime = Date()
                self.isLoading = false
                self.cacheStates()
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func findFlightByCallsign(_ callsign: String) -> OpenSkyState? {
        return currentStates.first { state in
            guard let stateCallsign = state.callsign else { return false }
            return stateCallsign.trimmingCharacters(in: .whitespaces).lowercased() == callsign.lowercased()
        }
    }
    
    func findFlightByICAO24(_ icao24: String) -> OpenSkyState? {
        return currentStates.first { $0.icao24 == icao24 }
    }
    
    func findFlightsInBounds(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D) -> [OpenSkyState] {
        return currentStates.filter { state in
            guard let lat = state.latitude, let lon = state.longitude else { return false }
            return lat >= southWest.latitude && lat <= northEast.latitude &&
                   lon >= southWest.longitude && lon <= northEast.longitude
        }
    }
    
    func getFlightProgress(for flight: SavedFlight, using openSkyState: OpenSkyState) -> FlightProgress? {
        guard let currentLat = openSkyState.latitude,
              let currentLon = openSkyState.longitude else { return nil }
        
        let currentPosition = CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon)
        let departureCoord = flight.departure.coordinate
        let arrivalCoord = flight.arrival.coordinate
        
        let totalDistance = calculateDistance(from: departureCoord, to: arrivalCoord)
        let distanceFromDeparture = calculateDistance(from: departureCoord, to: currentPosition)
        let distanceToArrival = calculateDistance(from: currentPosition, to: arrivalCoord)
        
        let progress = min(max(distanceFromDeparture / totalDistance, 0.0), 1.0)
        
        let currentSpeed = openSkyState.velocity ?? 0
        let estimatedTimeRemaining = currentSpeed > 0 ? (distanceToArrival * 1000) / currentSpeed : 0
        
        return FlightProgress(
            currentPosition: currentPosition,
            progressPercentage: progress,
            distanceRemaining: distanceToArrival,
            estimatedTimeRemaining: estimatedTimeRemaining,
            currentLocationName: getLocationName(for: currentPosition),
            altitude: openSkyState.baroAltitude ?? openSkyState.geoAltitude ?? 0,
            speed: currentSpeed,
            heading: openSkyState.trueTrack ?? 0,
            isOnGround: openSkyState.onGround,
            lastUpdated: Date()
        )
    }
    
    
    private func parseStates(from response: OpenSkyResponse) -> [OpenSkyState] {
        guard let stateArrays = response.states else { return [] }
        
        return stateArrays.compactMap { stateArray in
            OpenSkyState(from: stateArray)
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
    
    private func getLocationName(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 24.0 && lat <= 49.0 && lon >= -125.0 && lon <= -66.0 {
            return "United States"
        } else if lat >= 42.0 && lat <= 70.0 && lon >= -141.0 && lon <= -52.0 {
            return "Canada"
        } else if lat >= 49.0 && lat <= 61.0 && lon >= -8.0 && lon <= 2.0 {
            return "United Kingdom"
        } else if lat >= 42.0 && lat <= 51.0 && lon >= -5.0 && lon <= 9.0 {
            return "France"
        } else if lat >= 47.0 && lat <= 55.0 && lon >= 6.0 && lon <= 15.0 {
            return "Germany"
        } else if lat >= 36.0 && lat <= 47.0 && lon >= 6.0 && lon <= 19.0 {
            return "Italy"
        } else if lat >= 35.0 && lat <= 44.0 && lon >= -9.0 && lon <= 5.0 {
            return "Spain"
        } else if lat >= 31.0 && lat <= 46.0 && lon >= 125.0 && lon <= 146.0 {
            return "Japan"
        } else if lat >= -44.0 && lat <= -10.0 && lon >= 113.0 && lon <= 154.0 {
            return "Australia"
        } else if abs(lat) <= 90.0 && abs(lon) <= 180.0 {
            return determineOceanLocation(coordinate)
        } else {
            return "Unknown Location"
        }
    }
    
    private func determineOceanLocation(_ coordinate: CLLocationCoordinate2D) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lon >= -80.0 && lon <= 0.0 {
            if lat >= 0.0 {
                return "North Atlantic Ocean"
            } else {
                return "South Atlantic Ocean"
            }
        }
        else if lon >= -180.0 && lon <= -80.0 || lon >= 120.0 && lon <= 180.0 {
            if lat >= 0.0 {
                return "North Pacific Ocean"
            } else {
                return "South Pacific Ocean"
            }
        }
        else if lon >= 20.0 && lon <= 120.0 && lat <= 30.0 {
            return "Indian Ocean"
        }
        else if lat >= 66.0 {
            return "Arctic Ocean"
        }
        else if lat <= -60.0 {
            return "Antarctic Ocean"
        }
        
        return "International Waters"
    }
    
    private func cacheStates() {
        let cache = APIResponseCache(
            timestamp: Date(),
            data: try! JSONEncoder().encode(currentStates),
            expirationDate: Date().addingTimeInterval(300) // 5 minutes
        )
        
        if let cacheData = try? JSONEncoder().encode(cache) {
            userDefaults.set(cacheData, forKey: cacheKey)
        }
        
        userDefaults.set(Date(), forKey: lastUpdateKey)
    }
    
    private func loadCachedStates() {
        guard let cacheData = userDefaults.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode(APIResponseCache.self, from: cacheData),
              cache.expirationDate > Date() else { return }
        
        if let states = try? JSONDecoder().decode([OpenSkyState].self, from: cache.data) {
            currentStates = states
            lastUpdateTime = cache.timestamp
        }
    }
}


extension OpenSkyState {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var speedInKmh: Double? {
        guard let velocity = velocity else { return nil }
        return velocity * 3.6 // Convert m/s to km/h
    }
    
    var altitudeInFeet: Double? {
        guard let altitude = baroAltitude ?? geoAltitude else { return nil }
        return altitude * 3.28084 // Convert meters to feet
    }
}
