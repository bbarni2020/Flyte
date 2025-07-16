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
    
    enum CodingKeys: String, CodingKey {
        case flightNumber, departureDate, departureTime, gate, terminal, baggageReclaim, status, departure, arrival, airline, aircraft, routeData, isDownloaded
    }
    
    init(flightNumber: String, departureDate: Date, departureTime: Date, gate: String? = nil, terminal: String? = nil, baggageReclaim: String? = nil, status: FlightStatus = .scheduled, departure: Airport, arrival: Airport, airline: String, aircraft: String? = nil, routeData: RouteData? = nil, isDownloaded: Bool = false) {
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
            isDownloaded: true
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
            isDownloaded: isDownloaded
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
    @Published var isTracking = false
    @Published var isOfflineMode = false
    @Published var apiService = FlightAPIService.shared
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSavedFlights()
        addSampleDataIfNeeded()
    }
    
    private func addSampleDataIfNeeded() {
        if savedFlights.isEmpty {
            let sampleFlights = [
                SavedFlight(
                    flightNumber: "AA123",
                    departureDate: Date().addingTimeInterval(86400),
                    departureTime: Date().addingTimeInterval(86400 + 3600),
                    gate: "A12",
                    terminal: "1",
                    baggageReclaim: "5",
                    status: .scheduled,
                    departure: Airport(code: "LAX", name: "Los Angeles International", city: "Los Angeles", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 33.9425, longitude: -118.4081)),
                    arrival: Airport(code: "JFK", name: "John F. Kennedy International", city: "New York", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)),
                    airline: "American Airlines",
                    aircraft: "Boeing 737"
                ),
                SavedFlight(
                    flightNumber: "UA456",
                    departureDate: Date().addingTimeInterval(172800),
                    departureTime: Date().addingTimeInterval(172800 + 7200),
                    gate: "B8",
                    terminal: "2",
                    baggageReclaim: "3",
                    status: .boarding,
                    departure: Airport(code: "SFO", name: "San Francisco International", city: "San Francisco", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790)),
                    arrival: Airport(code: "ORD", name: "O'Hare International", city: "Chicago", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 41.9742, longitude: -87.9073)),
                    airline: "United Airlines",
                    aircraft: "Airbus A320"
                )
            ]
            savedFlights = sampleFlights
            saveFights()
        }
    }
    
    func addFlight(flightNumber: String, departureDate: Date, departureTime: Date) {
        let newFlight = SavedFlight(
            flightNumber: flightNumber,
            departureDate: departureDate,
            departureTime: departureTime,
            gate: "A" + String(Int.random(in: 1...20)),
            terminal: String(Int.random(in: 1...4)),
            baggageReclaim: String(Int.random(in: 1...10)),
            status: .scheduled,
            departure: Airport(code: "LAX", name: "Los Angeles International", city: "Los Angeles", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 33.9425, longitude: -118.4081)),
            arrival: Airport(code: "JFK", name: "John F. Kennedy International", city: "New York", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)),
            airline: "American Airlines"
        )
        
        savedFlights.append(newFlight)
        saveFights()
        
        fetchFlightDetails(for: newFlight)
    }
    
    func downloadRouteData(for flight: SavedFlight) {
        guard let index = savedFlights.firstIndex(where: { $0.id == flight.id }) else { return }
        
        let routeData = RouteData(
            waypoints: generateWaypoints(from: flight.departure.coordinate, to: flight.arrival.coordinate),
            duration: 5.5 * 3600,
            distance: 2475.0,
            offlineMapData: generateOfflineMapData()
        )
        
        let updatedFlight = flight.updatedWithDownload(routeData: routeData)
        savedFlights[index] = updatedFlight
        saveFights()
    }
    
    func startTracking(flight: SavedFlight) {
        currentTrackingFlight = flight
        isTracking = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateLiveFlightStatus()
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        isTracking = false
        liveFlightStatus = nil
        currentTrackingFlight = nil
    }
    
    func toggleOfflineMode() {
        isOfflineMode.toggle()
    }
    
    private func fetchFlightDetails(for flight: SavedFlight) {
        
    }
    
    private func updateLiveFlightStatus() {
        guard let flight = currentTrackingFlight else { return }
        
        let elapsed = Date().timeIntervalSince(flight.departureTime)
        let totalDuration = flight.routeData?.duration ?? 5.5 * 3600
        let progress = min(max(elapsed / totalDuration, 0.0), 1.0)
        
        let currentLocation = interpolateLocation(progress: progress, from: flight.departure.coordinate, to: flight.arrival.coordinate)
        let currentCountry = getCountryForLocation(currentLocation)
        
        liveFlightStatus = LiveFlightStatus(
            currentLocation: currentLocation,
            altitude: 35000 + sin(progress * .pi) * 5000,
            speed: 850 + Double.random(in: -50...50),
            progress: progress,
            currentCountry: currentCountry,
            estimatedTimeRemaining: totalDuration - elapsed,
            distanceRemaining: (flight.routeData?.distance ?? 2475.0) * (1.0 - progress),
            actualDepartureTime: flight.departureTime,
            estimatedArrivalTime: flight.departureTime.addingTimeInterval(totalDuration)
        )
    }
    
    private func interpolateLocation(progress: Double, from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * progress,
            longitude: start.longitude + (end.longitude - start.longitude) * progress
        )
    }
    
    private func generateWaypoints(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var waypoints: [CLLocationCoordinate2D] = []
        let steps = 10
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let waypoint = CLLocationCoordinate2D(
                latitude: start.latitude + (end.latitude - start.latitude) * progress,
                longitude: start.longitude + (end.longitude - start.longitude) * progress
            )
            waypoints.append(waypoint)
        }
        
        return waypoints
    }
    
    private func generateOfflineMapData() -> Data {
        return Data()
    }
    
    private func saveFights() {
        if let encoded = try? JSONEncoder().encode(savedFlights) {
            userDefaults.set(encoded, forKey: "savedFlights")
        }
    }
    
    private func loadSavedFlights() {
        if let data = userDefaults.data(forKey: "savedFlights"),
           let decoded = try? JSONDecoder().decode([SavedFlight].self, from: data) {
            savedFlights = decoded
        }
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
