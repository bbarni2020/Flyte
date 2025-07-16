import Foundation
import CoreLocation

struct FlightAPIResponse: Codable {
    let data: [FlightData]
    let pagination: Pagination?
}

struct FlightData: Codable {
    let flight_date: String
    let flight_status: String
    let departure: DepartureInfo
    let arrival: ArrivalInfo
    let airline: AirlineInfo
    let flight: FlightInfo
    let aircraft: AircraftInfo?
    let live: LiveInfo?
}

struct DepartureInfo: Codable {
    let airport: String
    let timezone: String
    let iata: String
    let icao: String
    let terminal: String?
    let gate: String?
    let delay: Int?
    let scheduled: String
    let estimated: String?
    let actual: String?
    let estimated_runway: String?
    let actual_runway: String?
}

struct ArrivalInfo: Codable {
    let airport: String
    let timezone: String
    let iata: String
    let icao: String
    let terminal: String?
    let gate: String?
    let baggage: String?
    let delay: Int?
    let scheduled: String
    let estimated: String?
    let actual: String?
    let estimated_runway: String?
    let actual_runway: String?
}

struct AirlineInfo: Codable {
    let name: String
    let iata: String
    let icao: String
}

struct FlightInfo: Codable {
    let number: String
    let iata: String
    let icao: String
    let codeshared: CodesharedInfo?
}

struct CodesharedInfo: Codable {
    let airline_name: String
    let airline_iata: String
    let airline_icao: String
    let flight_number: String
    let flight_iata: String
    let flight_icao: String
}

struct AircraftInfo: Codable {
    let registration: String?
    let iata: String?
    let icao: String?
    let icao24: String?
}

struct LiveInfo: Codable {
    let updated: String?
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let direction: Double?
    let speed_horizontal: Double?
    let speed_vertical: Double?
    let is_ground: Bool?
}

struct Pagination: Codable {
    let offset: Int
    let limit: Int
    let count: Int
    let total: Int
}

struct AirportAPIResponse: Codable {
    let data: [AirportData]
}

struct AirportData: Codable {
    let airport_name: String
    let iata_code: String
    let icao_code: String
    let latitude: String
    let longitude: String
    let geoname_id: String
    let timezone: String
    let gmt: String
    let phone_number: String?
    let country_name: String
    let country_iso2: String
    let city_iata_code: String
}

class FlightAPIService: ObservableObject {
    static let shared = FlightAPIService()
    
    private let baseURL = "http://api.aviationstack.com/v1"
    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "aviationstack_api_key") ?? ""
    }
    
    @Published var cachedFlights: [FlightData] = []
    @Published var cachedAirports: [String: AirportData] = [:]
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var hasValidAPIKey: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let flightsCacheKey = "cachedFlights"
    private let airportsCacheKey = "cachedAirports"
    private let lastUpdateKey = "lastUpdateTime"
    
    init() {
        loadCachedData()
        checkAPIKey()
    }
    
    private func checkAPIKey() {
        hasValidAPIKey = !apiKey.isEmpty
    }
    
    func preloadFlightData() async {
        guard !apiKey.isEmpty else {
            print("No API key provided")
            return
        }
        
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.isLoading = true
            }
            
            Task {
                await fetchFlights()
                await fetchAirports()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.lastUpdateTime = Date()
                    self.saveCachedData()
                }
                
                continuation.resume()
            }
        }
    }
    
    private func fetchFlights() async {
        guard !apiKey.isEmpty,
              let url = URL(string: "\(baseURL)/flights?access_key=\(apiKey)&limit=100") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FlightAPIResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.cachedFlights = response.data
            }
        } catch {
            print("Error fetching flights: \(error)")
        }
    }
    
    private func fetchAirports() async {
        guard !apiKey.isEmpty,
              let url = URL(string: "\(baseURL)/airports?access_key=\(apiKey)&limit=100") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AirportAPIResponse.self, from: data)
            
            DispatchQueue.main.async {
                for airport in response.data {
                    self.cachedAirports[airport.iata_code] = airport
                }
            }
        } catch {
            print("Error fetching airports: \(error)")
        }
    }
    
    private func loadCachedData() {
        if let flightsData = userDefaults.data(forKey: flightsCacheKey) {
            if let flights = try? JSONDecoder().decode([FlightData].self, from: flightsData) {
                cachedFlights = flights
            }
        }
        
        if let airportsData = userDefaults.data(forKey: airportsCacheKey) {
            if let airports = try? JSONDecoder().decode([String: AirportData].self, from: airportsData) {
                cachedAirports = airports
            }
        }
        
        if let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date {
            lastUpdateTime = lastUpdate
        }
    }
    
    private func saveCachedData() {
        if let flightsData = try? JSONEncoder().encode(cachedFlights) {
            userDefaults.set(flightsData, forKey: flightsCacheKey)
        }
        
        if let airportsData = try? JSONEncoder().encode(cachedAirports) {
            userDefaults.set(airportsData, forKey: airportsCacheKey)
        }
        
        if let lastUpdate = lastUpdateTime {
            userDefaults.set(lastUpdate, forKey: lastUpdateKey)
        }
    }
    
    func getFlightRoute(from flightData: FlightData) -> FlightRoute? {
        guard let depAirport = cachedAirports[flightData.departure.iata],
              let arrAirport = cachedAirports[flightData.arrival.iata] else {
            return nil
        }
        
        let departure = Airport(
            code: flightData.departure.iata,
            name: depAirport.airport_name,
            city: flightData.departure.airport,
            country: depAirport.country_name,
            coordinate: CLLocationCoordinate2D(
                latitude: Double(depAirport.latitude) ?? 0,
                longitude: Double(depAirport.longitude) ?? 0
            )
        )
        
        let arrival = Airport(
            code: flightData.arrival.iata,
            name: arrAirport.airport_name,
            city: flightData.arrival.airport,
            country: arrAirport.country_name,
            coordinate: CLLocationCoordinate2D(
                latitude: Double(arrAirport.latitude) ?? 0,
                longitude: Double(arrAirport.longitude) ?? 0
            )
        )
        
        let distance = calculateDistance(
            from: departure.coordinate,
            to: arrival.coordinate
        )
        
        let estimatedDuration = calculateFlightDuration(distance: distance)
        
        return FlightRoute(
            departure: departure,
            arrival: arrival,
            waypoints: generateWaypoints(from: departure.coordinate, to: arrival.coordinate),
            duration: estimatedDuration,
            distance: distance,
            flightNumber: flightData.flight.iata,
            airline: flightData.airline.name,
            aircraft: flightData.aircraft?.iata ?? "Unknown",
            scheduledDeparture: parseDate(flightData.departure.scheduled),
            scheduledArrival: parseDate(flightData.arrival.scheduled)
        )
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0
    }
    
    private func calculateFlightDuration(distance: Double) -> TimeInterval {
        let averageSpeed = 850.0
        return (distance / averageSpeed) * 3600
    }
    
    private func generateWaypoints(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var waypoints: [CLLocationCoordinate2D] = []
        let numberOfWaypoints = 5
        
        for i in 1..<numberOfWaypoints {
            let progress = Double(i) / Double(numberOfWaypoints)
            let latitude = from.latitude + (to.latitude - from.latitude) * progress
            let longitude = from.longitude + (to.longitude - from.longitude) * progress
            waypoints.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        
        return waypoints
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateString) ?? Date()
    }
    
    func searchFlights(departure: String? = nil, arrival: String? = nil) -> [FlightData] {
        var filteredFlights = cachedFlights
        
        if let dep = departure {
            filteredFlights = filteredFlights.filter { $0.departure.iata.contains(dep.uppercased()) }
        }
        
        if let arr = arrival {
            filteredFlights = filteredFlights.filter { $0.arrival.iata.contains(arr.uppercased()) }
        }
        
        return filteredFlights
    }
    
    func getFlightStatus(flightNumber: String) -> FlightData? {
        return cachedFlights.first { $0.flight.iata == flightNumber }
    }
}
