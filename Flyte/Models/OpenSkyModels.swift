//
//  OpenSkyModels.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreLocation

struct OpenSkyResponse: Codable {
    let time: TimeInterval
    let states: [[OpenSkyStateValue]]?
}

enum OpenSkyStateValue: Codable {
    case string(String)
    case double(Double)
    case int(Int)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

struct OpenSkyState: Codable {
    let icao24: String
    let callsign: String?
    let originCountry: String
    let timePosition: TimeInterval?
    let lastContact: TimeInterval
    let longitude: Double?
    let latitude: Double?
    let baroAltitude: Double?
    let onGround: Bool
    let velocity: Double?
    let trueTrack: Double?
    let verticalRate: Double?
    let sensors: [Int]?
    let geoAltitude: Double?
    let squawk: String?
    let spi: Bool
    let positionSource: Int
    
    init?(from values: [OpenSkyStateValue]) {
        guard values.count >= 17 else { return nil }
        
        guard case .string(let icao24) = values[0] else { return nil }
        self.icao24 = icao24
        
        if case .string(let callsign) = values[1] {
            self.callsign = callsign.trimmingCharacters(in: .whitespaces)
        } else {
            self.callsign = nil
        }
        
        guard case .string(let originCountry) = values[2] else { return nil }
        self.originCountry = originCountry
        
        if case .double(let timePosition) = values[3] {
            self.timePosition = timePosition
        } else {
            self.timePosition = nil
        }
        
        guard case .double(let lastContact) = values[4] else { return nil }
        self.lastContact = lastContact
        
        if case .double(let longitude) = values[5] {
            self.longitude = longitude
        } else {
            self.longitude = nil
        }
        
        if case .double(let latitude) = values[6] {
            self.latitude = latitude
        } else {
            self.latitude = nil
        }
        
        if case .double(let baroAltitude) = values[7] {
            self.baroAltitude = baroAltitude
        } else {
            self.baroAltitude = nil
        }
        
        guard case .int(let onGroundInt) = values[8] else { return nil }
        self.onGround = onGroundInt != 0
        
        if case .double(let velocity) = values[9] {
            self.velocity = velocity
        } else {
            self.velocity = nil
        }
        
        if case .double(let trueTrack) = values[10] {
            self.trueTrack = trueTrack
        } else {
            self.trueTrack = nil
        }
        
        if case .double(let verticalRate) = values[11] {
            self.verticalRate = verticalRate
        } else {
            self.verticalRate = nil
        }
        
        self.sensors = nil
        
        if case .double(let geoAltitude) = values[13] {
            self.geoAltitude = geoAltitude
        } else {
            self.geoAltitude = nil
        }
        
        if case .string(let squawk) = values[14] {
            self.squawk = squawk
        } else {
            self.squawk = nil
        }
        
        guard case .int(let spiInt) = values[15] else { return nil }
        self.spi = spiInt != 0
        
        guard case .int(let positionSource) = values[16] else { return nil }
        self.positionSource = positionSource
    }
}

struct FlightProgress {
    let currentPosition: CLLocationCoordinate2D
    let progressPercentage: Double
    let distanceRemaining: Double
    let estimatedTimeRemaining: TimeInterval
    let currentLocationName: String
    let altitude: Double
    let speed: Double
    let heading: Double
    let isOnGround: Bool
    let lastUpdated: Date
}

struct OfflineFlightEstimate {
    let estimatedPosition: CLLocationCoordinate2D
    let progressPercentage: Double
    let estimatedLocationName: String
    let timeElapsed: TimeInterval
    let estimatedTimeRemaining: TimeInterval
    let lastUpdated: Date
}

struct AirportDatabase: Codable {
    let airports: [AirportInfo]
}

struct AirportInfo: Codable {
    let id: Int
    let name: String
    let city: String
    let country: String
    let iata: String?
    let icao: String?
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timezone: String
    let dst: String
    let tzDatabaseTimeZone: String
    let type: String
    let source: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, city, country, iata, icao, latitude, longitude, altitude, timezone, dst, type, source
        case tzDatabaseTimeZone = "tz_database_time_zone"
    }
}

import CoreData

extension SavedFlight {
    func toFlightEntity(context: NSManagedObjectContext) -> FlightEntity {
        let entity = FlightEntity(context: context)
        entity.flightNumber = flightNumber
        entity.departureDate = departureDate
        entity.departureTime = departureTime
        entity.gate = gate
        entity.terminal = terminal
        entity.baggageReclaim = baggageReclaim
        entity.status = status.rawValue
        entity.departureAirportCode = departure.code
        entity.arrivalAirportCode = arrival.code
        entity.airline = airline
        entity.aircraft = aircraft
        entity.isDownloaded = isDownloaded
        
        if let routeData = routeData {
            entity.routeWaypoints = try? JSONEncoder().encode(routeData.waypoints)
            entity.routeDuration = routeData.duration
            entity.routeDistance = routeData.distance
            entity.offlineMapData = routeData.offlineMapData
        }
        
        return entity
    }
}

struct RouteCalculation {
    let waypoints: [CLLocationCoordinate2D]
    let totalDistance: Double
    let estimatedDuration: TimeInterval
    let segments: [RouteSegment]
}

struct RouteSegment {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let distance: Double
    let duration: TimeInterval
    let description: String
}

struct LocationInfo {
    let coordinate: CLLocationCoordinate2D
    let country: String
    let city: String?
    let region: String?
    let ocean: String?
    let timeZone: TimeZone?
}

struct APIResponseCache: Codable {
    let timestamp: Date
    let data: Data
    let expirationDate: Date
}

struct FlightTrackingCache: Codable {
    let flightNumber: String
    let icao24: String?
    let lastKnownPosition: CLLocationCoordinate2D?
    let lastUpdate: Date
    let apiSource: String
}
