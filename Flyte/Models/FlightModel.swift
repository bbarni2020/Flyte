import Foundation
import CoreLocation

struct SavedFlight: Codable, Identifiable {
    let id = UUID()
    let flightNumber: String
    let departureDate: Date
    let departureTime: Date
    let gate: String?
    let terminal: String?
    let baggageReclaim: String?
    let status: FlightStatus
    let departure: Airport
    let arrival: Airport
    let airline: String
    let aircraft: String?
    let routeData: RouteData?
    let isDownloaded: Bool
    let icao24: String? // Add ICAO24 transponder code for OpenSky tracking
    
    enum CodingKeys: String, CodingKey {
        case flightNumber, departureDate, departureTime, gate, terminal, baggageReclaim, status, departure, arrival, airline, aircraft, routeData, isDownloaded, icao24
    }
    
    init(flightNumber: String, departureDate: Date, departureTime: Date, gate: String? = nil, terminal: String? = nil, baggageReclaim: String? = nil, status: FlightStatus = .scheduled, departure: Airport, arrival: Airport, airline: String, aircraft: String? = nil, routeData: RouteData? = nil, isDownloaded: Bool = false, icao24: String? = nil) {
        self.flightNumber = flightNumber
        self.departureDate = departureDate
        self.departureTime = departureTime
        self.gate = gate
        self.terminal = terminal
        self.baggageReclaim = baggageReclaim
        self.status = status
        self.departure = departure
        self.arrival = arrival
        self.airline = airline
        self.aircraft = aircraft
        self.routeData = routeData
        self.isDownloaded = isDownloaded
        self.icao24 = icao24
    }
    
    func updatedWithDownload(routeData: RouteData) -> SavedFlight {
        return SavedFlight(
            flightNumber: flightNumber,
            departureDate: departureDate,
            departureTime: departureTime,
            gate: gate,
            terminal: terminal,
            baggageReclaim: baggageReclaim,
            status: status,
            departure: departure,
            arrival: arrival,
            airline: airline,
            aircraft: aircraft,
            routeData: routeData,
            isDownloaded: true,
            icao24: icao24
        )
    }
    
    func updatedWithDetails(gate: String?, terminal: String?, baggageReclaim: String?, status: FlightStatus) -> SavedFlight {
        return SavedFlight(
            flightNumber: flightNumber,
            departureDate: departureDate,
            departureTime: departureTime,
            gate: gate,
            terminal: terminal,
            baggageReclaim: baggageReclaim,
            status: status,
            departure: departure,
            arrival: arrival,
            airline: airline,
            aircraft: aircraft,
            routeData: routeData,
            isDownloaded: isDownloaded,
            icao24: icao24
        )
    }
    
    func updatedWithICAO24(_ icao24: String) -> SavedFlight {
        return SavedFlight(
            flightNumber: flightNumber,
            departureDate: departureDate,
            departureTime: departureTime,
            gate: gate,
            terminal: terminal,
            baggageReclaim: baggageReclaim,
            status: status,
            departure: departure,
            arrival: arrival,
            airline: airline,
            aircraft: aircraft,
            routeData: routeData,
            isDownloaded: isDownloaded,
            icao24: icao24
        )
    }
}

struct RouteData: Codable {
    let waypoints: [CLLocationCoordinate2D]
    let duration: TimeInterval
    let distance: Double
    let offlineMapData: Data?
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

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

struct Airport: Codable {
    let code: String
    let name: String
    let city: String
    let country: String
    let coordinate: CLLocationCoordinate2D
}

enum FlightStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case delayed = "Delayed"
    case boarding = "Boarding"
    case departed = "Departed"
    case inAir = "In Air"
    case landed = "Landed"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .delayed: return "orange"
        case .boarding: return "green"
        case .departed: return "purple"
        case .inAir: return "cyan"
        case .landed: return "green"
        case .cancelled: return "red"
        }
    }
}

struct LiveFlightStatus {
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

class FlightManager: ObservableObject {
    @Published var savedFlights: [SavedFlight] = []
    @Published var currentTrackingFlight: SavedFlight?
    @Published var liveFlightStatus: LiveFlightStatus?
    @Published var flightProgress: FlightProgress?
    @Published var isTracking = false
    @Published var isOfflineMode = false
    @Published var apiService = FlightAPIService.shared
    @Published var openSkyService = OpenSkyService.shared
    @Published var offlineService = OfflineFlightService.shared
    @Published var airportService = AirportDatabaseService.shared
    @Published var coreDataService = CoreDataService.shared
    
    private var timer: Timer?
    private var trackingTimer: Timer?
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSavedFlights()
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
    
    func addFlight(flightNumber: String, departureDate: Date, departureTime: Date) {
        let cleanFlightNumber = flightNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            if let flightData = await apiService.fetchFlightDetails(for: cleanFlightNumber) {
                await MainActor.run {
                    let departure = self.airportService.findAirport(by: flightData.departure.iata)?.toAirport() ?? 
                        Airport(code: flightData.departure.iata, name: flightData.departure.airport, 
                               city: flightData.departure.airport, country: "Unknown", 
                               coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
                    
                    let arrival = self.airportService.findAirport(by: flightData.arrival.iata)?.toAirport() ?? 
                        Airport(code: flightData.arrival.iata, name: flightData.arrival.airport, 
                               city: flightData.arrival.airport, country: "Unknown", 
                               coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
                    
                    let newFlight = SavedFlight(
                        flightNumber: cleanFlightNumber,
                        departureDate: departureDate,
                        departureTime: departureTime,
                        gate: flightData.departure.gate,
                        terminal: flightData.departure.terminal,
                        baggageReclaim: flightData.arrival.baggage,
                        status: self.parseFlightStatus(flightData.flight_status),
                        departure: departure,
                        arrival: arrival,
                        airline: flightData.airline.name,
                        aircraft: flightData.aircraft?.iata
                    )
                    
                    self.savedFlights.append(newFlight)
                    self.saveFights()
                    self.coreDataService.saveFlight(newFlight)
                }
            } else {
                await MainActor.run {
                    let newFlight = SavedFlight(
                        flightNumber: cleanFlightNumber,
                        departureDate: departureDate,
                        departureTime: departureTime,
                        departure: Airport(code: "LAX", name: "Los Angeles International", city: "Los Angeles", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 33.9425, longitude: -118.4081)),
                        arrival: Airport(code: "JFK", name: "John F. Kennedy International", city: "New York", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)),
                        airline: "Unknown Airline"
                    )
                    
                    self.savedFlights.append(newFlight)
                    self.saveFights()
                    self.coreDataService.saveFlight(newFlight)
                }
            }
        }
    }
    
    private func parseFlightStatus(_ status: String) -> FlightStatus {
        switch status.lowercased() {
        case "scheduled": return .scheduled
        case "active", "en-route": return .inAir
        case "landed": return .landed
        case "cancelled": return .cancelled
        case "delayed": return .delayed
        default: return .scheduled
        }
    }
    
    func deleteFlight(_ flight: SavedFlight) {
        if let index = savedFlights.firstIndex(where: { $0.id == flight.id }) {
            savedFlights.remove(at: index)
            saveFights()
            coreDataService.deleteFlight(flight)
            
            if currentTrackingFlight?.id == flight.id {
                stopTracking()
            }
        }
    }
    
    func downloadRouteData(for flight: SavedFlight) {
        guard let index = savedFlights.firstIndex(where: { $0.id == flight.id }) else { return }
        
        Task {
            if let routeWaypoints = await apiService.fetchFlightRoute(for: flight.flightNumber) {
                let routeData = RouteData(
                    waypoints: routeWaypoints,
                    duration: estimateFlightDuration(from: flight.departure.coordinate, to: flight.arrival.coordinate),
                    distance: calculateDistance(from: flight.departure.coordinate, to: flight.arrival.coordinate),
                    offlineMapData: nil // Will be populated by map service
                )
                
                await MainActor.run {
                    let updatedFlight = flight.updatedWithDownload(routeData: routeData)
                    self.savedFlights[index] = updatedFlight
                    self.saveFights()
                    self.coreDataService.updateFlight(updatedFlight)
                }
            }
        }
    }
    
    private func estimateFlightDuration(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> TimeInterval {
        let distance = calculateDistance(from: from, to: to)
        let averageSpeed = 850.0 // km/h
        return (distance / averageSpeed) * 3600
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0
    }
    
    func startTracking(flight: SavedFlight) {
        currentTrackingFlight = flight
        isTracking = true
        
        openSkyService.startRealTimeTracking(updateInterval: 45)
        
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateLiveFlightStatus()
        }
        
        offlineService.startOfflineTracking(for: flight)
    }
    
    func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        timer?.invalidate()
        timer = nil
        isTracking = false
        liveFlightStatus = nil
        flightProgress = nil
        currentTrackingFlight = nil
        
        openSkyService.stopTracking()
        offlineService.stopOfflineTracking()
    }
    
    func toggleOfflineMode() {
        isOfflineMode.toggle()
        
        if isOfflineMode {
            openSkyService.stopTracking()
            if let flight = currentTrackingFlight {
                offlineService.startOfflineTracking(for: flight)
            }
        } else {
            openSkyService.startRealTimeTracking(updateInterval: 45)
            offlineService.stopOfflineTracking()
        }
    }
    
    private func fetchFlightDetails(for flight: SavedFlight) {
        Task {
            if let flightData = await apiService.fetchFlightDetails(for: flight.flightNumber) {
                await MainActor.run {
                    if let index = self.savedFlights.firstIndex(where: { $0.id == flight.id }) {
                        let updatedFlight = flight.updatedWithDetails(
                            gate: flightData.departure.gate,
                            terminal: flightData.departure.terminal,
                            baggageReclaim: flightData.arrival.baggage,
                            status: self.parseFlightStatus(flightData.flight_status)
                        )
                        self.savedFlights[index] = updatedFlight
                        self.saveFights()
                        self.coreDataService.updateFlight(updatedFlight)
                    }
                }
            }
        }
    }
    
    private func updateLiveFlightStatus() {
        guard let flight = currentTrackingFlight else { return }
        
        if isOfflineMode {
            if let offlineEstimate = offlineService.calculateOfflineProgress(for: flight) {
                liveFlightStatus = LiveFlightStatus(
                    currentLocation: offlineEstimate.estimatedPosition,
                    altitude: 35000, // Estimated cruise altitude
                    speed: 850, // Estimated cruise speed
                    progress: offlineEstimate.progressPercentage,
                    currentCountry: offlineEstimate.estimatedLocationName,
                    estimatedTimeRemaining: offlineEstimate.estimatedTimeRemaining,
                    distanceRemaining: calculateDistance(from: offlineEstimate.estimatedPosition, to: flight.arrival.coordinate),
                    actualDepartureTime: flight.departureTime,
                    estimatedArrivalTime: flight.departureTime.addingTimeInterval(flight.routeData?.duration ?? estimateFlightDuration(from: flight.departure.coordinate, to: flight.arrival.coordinate))
                )
            }
        } else {
            if let openSkyState = findOpenSkyState(for: flight) {
                if let progress = openSkyService.getFlightProgress(for: flight, using: openSkyState) {
                    flightProgress = progress
                    
                    liveFlightStatus = LiveFlightStatus(
                        currentLocation: progress.currentPosition,
                        altitude: progress.altitude,
                        speed: progress.speed,
                        progress: progress.progressPercentage,
                        currentCountry: progress.currentLocationName,
                        estimatedTimeRemaining: progress.estimatedTimeRemaining,
                        distanceRemaining: progress.distanceRemaining,
                        actualDepartureTime: flight.departureTime,
                        estimatedArrivalTime: Date().addingTimeInterval(progress.estimatedTimeRemaining)
                    )
                }
            } else {
                if let offlineEstimate = offlineService.calculateOfflineProgress(for: flight) {
                    liveFlightStatus = LiveFlightStatus(
                        currentLocation: offlineEstimate.estimatedPosition,
                        altitude: 35000,
                        speed: 850,
                        progress: offlineEstimate.progressPercentage,
                        currentCountry: offlineEstimate.estimatedLocationName,
                        estimatedTimeRemaining: offlineEstimate.estimatedTimeRemaining,
                        distanceRemaining: calculateDistance(from: offlineEstimate.estimatedPosition, to: flight.arrival.coordinate),
                        actualDepartureTime: flight.departureTime,
                        estimatedArrivalTime: flight.departureTime.addingTimeInterval(flight.routeData?.duration ?? estimateFlightDuration(from: flight.departure.coordinate, to: flight.arrival.coordinate))
                    )
                }
            }
        }
    }
    
    private func findOpenSkyState(for flight: SavedFlight) -> OpenSkyState? {
        if let state = openSkyService.findFlightByCallsign(flight.flightNumber) {
            return state
        }
        
        if let cache = coreDataService.loadFlightCache(for: flight.flightNumber),
           let icao24 = cache.icao24 {
            return openSkyService.findFlightByICAO24(icao24)
        }
        
        let departureBounds = createBounds(around: flight.departure.coordinate, radius: 100)
        let arrivalBounds = createBounds(around: flight.arrival.coordinate, radius: 100)
        
        let nearbyFlights = openSkyService.findFlightsInBounds(
            northEast: departureBounds.northEast,
            southWest: departureBounds.southWest
        ) + openSkyService.findFlightsInBounds(
            northEast: arrivalBounds.northEast,
            southWest: arrivalBounds.southWest
        )
        
        return nearbyFlights.first { state in
            guard let callsign = state.callsign else { return false }
            return callsign.contains(flight.flightNumber.prefix(2)) // Airline code match
        }
    }
    
    private func createBounds(around center: CLLocationCoordinate2D, radius: Double) -> (northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D) {
        let latDelta = radius / 111.0 // Approximate km per degree
        let lonDelta = radius / (111.0 * cos(center.latitude * .pi / 180))
        
        return (
            northEast: CLLocationCoordinate2D(latitude: center.latitude + latDelta, longitude: center.longitude + lonDelta),
            southWest: CLLocationCoordinate2D(latitude: center.latitude - latDelta, longitude: center.longitude - lonDelta)
        )
    }
    
    private func interpolateLocation(progress: Double, from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
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
    
    private func generateWaypoints(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var waypoints: [CLLocationCoordinate2D] = []
        let steps = 20 // More waypoints for smoother tracking
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let waypoint = interpolateLocation(progress: progress, from: start, to: end)
            waypoints.append(waypoint)
        }
        
        return waypoints
    }
    
    private func generateOfflineMapData() -> Data {
        return Data()
    }
    
    private func saveFights() {
        for flight in savedFlights {
            coreDataService.saveFlight(flight)
        }
        
        if let encoded = try? JSONEncoder().encode(savedFlights) {
            userDefaults.set(encoded, forKey: "savedFlights")
        }
    }
    
    private func loadSavedFlights() {
        savedFlights = coreDataService.loadFlights()
        
        if savedFlights.isEmpty {
            if let data = userDefaults.data(forKey: "savedFlights"),
               let decoded = try? JSONDecoder().decode([SavedFlight].self, from: data) {
                savedFlights = decoded
                
                for flight in savedFlights {
                    coreDataService.saveFlight(flight)
                }
            }
        }
    }
}
