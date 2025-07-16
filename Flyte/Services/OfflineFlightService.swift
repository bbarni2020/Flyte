//
//  OfflineFlightService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreLocation

class OfflineFlightService: ObservableObject {
    static let shared = OfflineFlightService()
    
    @Published var offlineEstimate: OfflineFlightEstimate?
    @Published var isOfflineMode = false
    
    private var offlineTimer: Timer?
    private var currentFlight: SavedFlight?
    
    init() {}
    
    
    func startOfflineTracking(for flight: SavedFlight) {
        currentFlight = flight
        isOfflineMode = true
        
        offlineTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateOfflineEstimate()
        }
        
        updateOfflineEstimate()
    }
    
    func stopOfflineTracking() {
        offlineTimer?.invalidate()
        offlineTimer = nil
        currentFlight = nil
        isOfflineMode = false
        offlineEstimate = nil
    }
    
    func calculateOfflineProgress(for flight: SavedFlight, at time: Date = Date()) -> OfflineFlightEstimate? {
        let departureTime = flight.departureTime
        let arrivalTime = flight.departureTime.addingTimeInterval(flight.routeData?.duration ?? estimateFlightDuration(for: flight))
        
        let timeElapsed = time.timeIntervalSince(departureTime)
        let totalDuration = arrivalTime.timeIntervalSince(departureTime)
        
        if timeElapsed < 0 {
            return OfflineFlightEstimate(
                estimatedPosition: flight.departure.coordinate,
                progressPercentage: 0.0,
                estimatedLocationName: "\(flight.departure.city), \(flight.departure.country)",
                timeElapsed: 0,
                estimatedTimeRemaining: totalDuration,
                lastUpdated: time
            )
        }
        
        let progress = min(timeElapsed / totalDuration, 1.0)
        
        let estimatedPosition = interpolatePosition(
            from: flight.departure.coordinate,
            to: flight.arrival.coordinate,
            progress: progress
        )
        
        let timeRemaining = max(totalDuration - timeElapsed, 0)
        
        let locationName = getLocationName(for: estimatedPosition)
        
        return OfflineFlightEstimate(
            estimatedPosition: estimatedPosition,
            progressPercentage: progress,
            estimatedLocationName: locationName,
            timeElapsed: timeElapsed,
            estimatedTimeRemaining: timeRemaining,
            lastUpdated: time
        )
    }
    
    
    private func updateOfflineEstimate() {
        guard let flight = currentFlight else { return }
        
        offlineEstimate = calculateOfflineProgress(for: flight)
    }
    
    private func estimateFlightDuration(for flight: SavedFlight) -> TimeInterval {
        let distance = calculateDistance(from: flight.departure.coordinate, to: flight.arrival.coordinate)
        let averageSpeed = 850.0 // km/h
        return (distance / averageSpeed) * 3600 // Convert to seconds
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
    
    private func interpolatePosition(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, progress: Double) -> CLLocationCoordinate2D {
        let startLat = start.latitude * .pi / 180
        let startLon = start.longitude * .pi / 180
        let endLat = end.latitude * .pi / 180
        let endLon = end.longitude * .pi / 180
        
        let d = 2 * asin(sqrt(pow(sin((startLat - endLat) / 2), 2) + cos(startLat) * cos(endLat) * pow(sin((startLon - endLon) / 2), 2)))
        
        let a = sin((1 - progress) * d) / sin(d)
        let b = sin(progress * d) / sin(d)
        
        let x = a * cos(startLat) * cos(startLon) + b * cos(endLat) * cos(endLon)
        let y = a * cos(startLat) * sin(startLon) + b * cos(endLat) * sin(endLon)
        let z = a * sin(startLat) + b * sin(endLat)
        
        let resultLat = atan2(z, sqrt(x * x + y * y))
        let resultLon = atan2(y, x)
        
        return CLLocationCoordinate2D(
            latitude: resultLat * 180 / .pi,
            longitude: resultLon * 180 / .pi
        )
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
}
