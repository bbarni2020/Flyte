import Foundation
import CoreLocation

struct FlightRoute {
    let id = UUID()
    let departure: Airport
    let arrival: Airport
    let waypoints: [CLLocationCoordinate2D]
    let duration: TimeInterval
    let distance: Double
    let flightNumber: String
    let airline: String
    let aircraft: String
    let scheduledDeparture: Date
    let scheduledArrival: Date
}

struct Airport {
    let code: String
    let name: String
    let city: String
    let country: String
    let coordinate: CLLocationCoordinate2D
}

struct FlightStatus {
    let currentLocation: CLLocationCoordinate2D
    let altitude: Double
    let speed: Double
    let progress: Double
    let currentCountry: String
    let estimatedTimeRemaining: TimeInterval
    let distanceRemaining: Double
    let actualDepartureTime: Date?
    let estimatedArrivalTime: Date
}

class FlightTracker: ObservableObject {
    @Published var currentFlight: FlightRoute?
    @Published var flightStatus: FlightStatus?
    @Published var isTracking = false
    @Published var departureTime: Date?
    @Published var apiService = FlightAPIService.shared
    
    private var timer: Timer?
    
    func startTracking(flight: FlightRoute, departureTime: Date) {
        self.currentFlight = flight
        self.departureTime = departureTime
        self.isTracking = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateFlightStatus()
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        isTracking = false
        flightStatus = nil
    }
    
    private func updateFlightStatus() {
        guard let flight = currentFlight,
              let departure = departureTime else { return }
        
        let elapsed = Date().timeIntervalSince(departure)
        let progress = min(elapsed / flight.duration, 1.0)
        
        let currentLocation = interpolateLocation(progress: progress, route: flight)
        let currentCountry = getCountryForLocation(currentLocation)
        
        flightStatus = FlightStatus(
            currentLocation: currentLocation,
            altitude: 35000 + sin(progress * .pi) * 5000,
            speed: 850 + Double.random(in: -50...50),
            progress: progress,
            currentCountry: currentCountry,
            estimatedTimeRemaining: flight.duration - elapsed,
            distanceRemaining: flight.distance * (1.0 - progress),
            actualDepartureTime: departure,
            estimatedArrivalTime: flight.scheduledArrival
        )
    }
    
    private func interpolateLocation(progress: Double, route: FlightRoute) -> CLLocationCoordinate2D {
        let startLat = route.departure.coordinate.latitude
        let startLng = route.departure.coordinate.longitude
        let endLat = route.arrival.coordinate.latitude
        let endLng = route.arrival.coordinate.longitude
        
        return CLLocationCoordinate2D(
            latitude: startLat + (endLat - startLat) * progress,
            longitude: startLng + (endLng - startLng) * progress
        )
    }
    
    private func getCountryForLocation(_ location: CLLocationCoordinate2D) -> String {
        let lat = location.latitude
        let lng = location.longitude
        
        if lat >= 24.0 && lat <= 49.0 && lng >= -125.0 && lng <= -66.0 {
            return "United States"
        } else if lat >= 42.0 && lat <= 70.0 && lng >= -141.0 && lng <= -52.0 {
            return "Canada"
        } else if lat >= 49.0 && lat <= 61.0 && lng >= -8.0 && lng <= 2.0 {
            return "United Kingdom"
        } else if lat >= 42.0 && lat <= 51.0 && lng >= -5.0 && lng <= 9.0 {
            return "France"
        } else if lat >= 47.0 && lat <= 55.0 && lng >= 6.0 && lng <= 15.0 {
            return "Germany"
        } else if lat >= 36.0 && lat <= 47.0 && lng >= 6.0 && lng <= 19.0 {
            return "Italy"
        } else if lat >= 35.0 && lat <= 44.0 && lng >= -9.0 && lng <= 5.0 {
            return "Spain"
        } else if lat >= 31.0 && lat <= 46.0 && lng >= 125.0 && lng <= 146.0 {
            return "Japan"
        } else if lat >= -44.0 && lat <= -10.0 && lng >= 113.0 && lng <= 154.0 {
            return "Australia"
        } else if lat >= 0.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0 {
            return "Over Ocean"
        } else {
            return "International Waters"
        }
    }
}
