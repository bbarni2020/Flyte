//
//  AirportDatabaseService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreLocation

class AirportDatabaseService: ObservableObject {
    static let shared = AirportDatabaseService()
    
    @Published var airports: [AirportInfo] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "airports_database_cache"
    private let lastUpdateKey = "airports_last_update"
    
    init() {
        loadCachedAirports()
        if airports.isEmpty {
            loadBundledAirports()
        }
    }
    
    
    func findAirport(by iataCode: String) -> AirportInfo? {
        return airports.first { $0.iata?.uppercased() == iataCode.uppercased() }
    }
    
    func findAirport(byICAO icaoCode: String) -> AirportInfo? {
        return airports.first { $0.icao?.uppercased() == icaoCode.uppercased() }
    }
    
    func findAirports(near coordinate: CLLocationCoordinate2D, within radius: Double) -> [AirportInfo] {
        return airports.filter { airport in
            let distance = calculateDistance(
                from: coordinate,
                to: CLLocationCoordinate2D(latitude: airport.latitude, longitude: airport.longitude)
            )
            return distance <= radius
        }
    }
    
    func searchAirports(query: String) -> [AirportInfo] {
        let lowercasedQuery = query.lowercased()
        return airports.filter { airport in
            airport.name.lowercased().contains(lowercasedQuery) ||
            airport.city.lowercased().contains(lowercasedQuery) ||
            airport.country.lowercased().contains(lowercasedQuery) ||
            airport.iata?.lowercased().contains(lowercasedQuery) == true ||
            airport.icao?.lowercased().contains(lowercasedQuery) == true
        }
    }
    
    func getAirportTimeZone(for iataCode: String) -> TimeZone? {
        guard let airport = findAirport(by: iataCode) else { return nil }
        return TimeZone(identifier: airport.tzDatabaseTimeZone)
    }
    
    func downloadAirportDatabase() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        loadBundledAirports()
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    
    private func loadBundledAirports() {
        let sampleAirports = [
            AirportInfo(
                id: 1,
                name: "Los Angeles International Airport",
                city: "Los Angeles",
                country: "United States",
                iata: "LAX",
                icao: "KLAX",
                latitude: 33.9425,
                longitude: -118.4081,
                altitude: 125,
                timezone: "-8",
                dst: "A",
                tzDatabaseTimeZone: "America/Los_Angeles",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 2,
                name: "John F Kennedy International Airport",
                city: "New York",
                country: "United States",
                iata: "JFK",
                icao: "KJFK",
                latitude: 40.639751,
                longitude: -73.778925,
                altitude: 13,
                timezone: "-5",
                dst: "A",
                tzDatabaseTimeZone: "America/New_York",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 3,
                name: "San Francisco International Airport",
                city: "San Francisco",
                country: "United States",
                iata: "SFO",
                icao: "KSFO",
                latitude: 37.621311,
                longitude: -122.378968,
                altitude: 13,
                timezone: "-8",
                dst: "A",
                tzDatabaseTimeZone: "America/Los_Angeles",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 4,
                name: "Chicago O'Hare International Airport",
                city: "Chicago",
                country: "United States",
                iata: "ORD",
                icao: "KORD",
                latitude: 41.978142,
                longitude: -87.904722,
                altitude: 672,
                timezone: "-6",
                dst: "A",
                tzDatabaseTimeZone: "America/Chicago",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 5,
                name: "London Heathrow Airport",
                city: "London",
                country: "United Kingdom",
                iata: "LHR",
                icao: "EGLL",
                latitude: 51.4775,
                longitude: -0.461389,
                altitude: 83,
                timezone: "0",
                dst: "E",
                tzDatabaseTimeZone: "Europe/London",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 6,
                name: "Charles de Gaulle Airport",
                city: "Paris",
                country: "France",
                iata: "CDG",
                icao: "LFPG",
                latitude: 49.009722,
                longitude: 2.547778,
                altitude: 392,
                timezone: "1",
                dst: "E",
                tzDatabaseTimeZone: "Europe/Paris",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 7,
                name: "Frankfurt Airport",
                city: "Frankfurt",
                country: "Germany",
                iata: "FRA",
                icao: "EDDF",
                latitude: 50.033333,
                longitude: 8.570556,
                altitude: 364,
                timezone: "1",
                dst: "E",
                tzDatabaseTimeZone: "Europe/Berlin",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 8,
                name: "Tokyo Haneda Airport",
                city: "Tokyo",
                country: "Japan",
                iata: "HND",
                icao: "RJTT",
                latitude: 35.552258,
                longitude: 139.779694,
                altitude: 35,
                timezone: "9",
                dst: "U",
                tzDatabaseTimeZone: "Asia/Tokyo",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 9,
                name: "Sydney Kingsford Smith Airport",
                city: "Sydney",
                country: "Australia",
                iata: "SYD",
                icao: "YSSY",
                latitude: -33.946667,
                longitude: 151.177222,
                altitude: 21,
                timezone: "10",
                dst: "O",
                tzDatabaseTimeZone: "Australia/Sydney",
                type: "airport",
                source: "OurAirports"
            ),
            AirportInfo(
                id: 10,
                name: "Dubai International Airport",
                city: "Dubai",
                country: "United Arab Emirates",
                iata: "DXB",
                icao: "OMDB",
                latitude: 25.252778,
                longitude: 55.364444,
                altitude: 62,
                timezone: "4",
                dst: "U",
                tzDatabaseTimeZone: "Asia/Dubai",
                type: "airport",
                source: "OurAirports"
            )
        ]
        
        airports = sampleAirports
        cacheAirports()
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
    
    private func cacheAirports() {
        if let data = try? JSONEncoder().encode(airports) {
            userDefaults.set(data, forKey: cacheKey)
        }
        userDefaults.set(Date(), forKey: lastUpdateKey)
    }
    
    private func loadCachedAirports() {
        guard let data = userDefaults.data(forKey: cacheKey) else { return }
        
        if let cachedAirports = try? JSONDecoder().decode([AirportInfo].self, from: data) {
            airports = cachedAirports
        }
    }
}


extension AirportInfo {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        if let iata = iata {
            return "\(iata) - \(name)"
        } else {
            return name
        }
    }
    
    var cityCountry: String {
        return "\(city), \(country)"
    }
    
    func toAirport() -> Airport {
        return Airport(
            code: iata ?? icao ?? "",
            name: name,
            city: city,
            country: country,
            coordinate: coordinate
        )
    }
}
