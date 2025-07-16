//
//  GeocodeService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreLocation

class GeocodeService: ObservableObject {
    static let shared = GeocodeService()
    
    private let geocoder = CLGeocoder()
    private var cache: [String: LocationInfo] = [:]
    private let cacheQueue = DispatchQueue(label: "geocode.cache", attributes: .concurrent)
    
    init() {
    }
    
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> LocationInfo? {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"
        
        let cachedResult = cacheQueue.sync {
            return cache[cacheKey]
        }
        
        if let cached = cachedResult {
            return cached
        }
        
        if let info = await reverseGeocodeWithApple(coordinate: coordinate) {
            cacheQueue.async(flags: .barrier) {
                self.cache[cacheKey] = info
                if self.cache.count > 100 {
                    let keysToRemove = Array(self.cache.keys).prefix(20)
                    for key in keysToRemove {
                        self.cache.removeValue(forKey: key)
                    }
                }
            }
            return info
        }
        
        return getLocationInfoFromDatabase(coordinate: coordinate)
    }
    
    func getLocationName(for coordinate: CLLocationCoordinate2D) async -> String {
        if let info = await reverseGeocode(coordinate: coordinate) {
            if let city = info.city {
                return "\(city), \(info.country)"
            } else if !info.country.isEmpty {
                return info.country
            } else if let ocean = info.ocean {
                return ocean
            }
        }
        
        return "Unknown Location"
    }
    
    
    private func reverseGeocodeWithApple(coordinate: CLLocationCoordinate2D) async -> LocationInfo? {
        return await withCheckedContinuation { continuation in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let info = LocationInfo(
                    coordinate: coordinate,
                    country: placemark.country ?? "Unknown",
                    city: placemark.locality ?? placemark.administrativeArea,
                    region: placemark.administrativeArea,
                    ocean: nil,
                    timeZone: placemark.timeZone
                )
                
                continuation.resume(returning: info)
            }
        }
    }
    
    private func getLocationInfoFromDatabase(coordinate: CLLocationCoordinate2D) -> LocationInfo {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if let countryInfo = getCountryInfo(for: coordinate) {
            return LocationInfo(
                coordinate: coordinate,
                country: countryInfo.country,
                city: countryInfo.city,
                region: countryInfo.region,
                ocean: nil,
                timeZone: countryInfo.timeZone
            )
        } else {
            let ocean = determineOcean(for: coordinate)
            return LocationInfo(
                coordinate: coordinate,
                country: "International Waters",
                city: nil,
                region: nil,
                ocean: ocean,
                timeZone: nil
            )
        }
    }
    
    private func getCountryInfo(for coordinate: CLLocationCoordinate2D) -> CountryInfo? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        let countries: [CountryInfo] = [
            CountryInfo(
                bounds: (24.0, 49.0, -125.0, -66.0),
                country: "United States",
                city: getCityForUSCoordinate(coordinate),
                region: "North America",
                timeZone: getUSTimeZone(for: coordinate)
            ),
            CountryInfo(
                bounds: (42.0, 70.0, -141.0, -52.0),
                country: "Canada",
                city: getCityForCanadaCoordinate(coordinate),
                region: "North America",
                timeZone: getCanadaTimeZone(for: coordinate)
            ),
            CountryInfo(
                bounds: (49.0, 61.0, -8.0, 2.0),
                country: "United Kingdom",
                city: getCityForUKCoordinate(coordinate),
                region: "Europe",
                timeZone: TimeZone(identifier: "Europe/London")
            ),
            CountryInfo(
                bounds: (42.0, 51.0, -5.0, 9.0),
                country: "France",
                city: getCityForFranceCoordinate(coordinate),
                region: "Europe",
                timeZone: TimeZone(identifier: "Europe/Paris")
            ),
            CountryInfo(
                bounds: (47.0, 55.0, 6.0, 15.0),
                country: "Germany",
                city: getCityForGermanyCoordinate(coordinate),
                region: "Europe",
                timeZone: TimeZone(identifier: "Europe/Berlin")
            ),
            CountryInfo(
                bounds: (36.0, 47.0, 6.0, 19.0),
                country: "Italy",
                city: getCityForItalyCoordinate(coordinate),
                region: "Europe",
                timeZone: TimeZone(identifier: "Europe/Rome")
            ),
            CountryInfo(
                bounds: (35.0, 44.0, -9.0, 5.0),
                country: "Spain",
                city: getCityForSpainCoordinate(coordinate),
                region: "Europe",
                timeZone: TimeZone(identifier: "Europe/Madrid")
            ),
            CountryInfo(
                bounds: (31.0, 46.0, 125.0, 146.0),
                country: "Japan",
                city: getCityForJapanCoordinate(coordinate),
                region: "Asia",
                timeZone: TimeZone(identifier: "Asia/Tokyo")
            ),
            CountryInfo(
                bounds: (-44.0, -10.0, 113.0, 154.0),
                country: "Australia",
                city: getCityForAustraliaCoordinate(coordinate),
                region: "Oceania",
                timeZone: getAustraliaTimeZone(for: coordinate)
            )
        ]
        
        for country in countries {
            if lat >= country.bounds.0 && lat <= country.bounds.1 &&
               lon >= country.bounds.2 && lon <= country.bounds.3 {
                return country
            }
        }
        
        return nil
    }
    
    private func determineOcean(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lon >= -80.0 && lon <= 20.0 {
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
    
    
    private func getCityForUSCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 33.7 && lat <= 34.1 && lon >= -118.7 && lon <= -118.1 {
            return "Los Angeles"
        } else if lat >= 40.4 && lat <= 40.9 && lon >= -74.3 && lon <= -73.7 {
            return "New York"
        } else if lat >= 37.4 && lat <= 37.8 && lon >= -122.5 && lon <= -122.3 {
            return "San Francisco"
        } else if lat >= 41.6 && lat <= 42.1 && lon >= -88.0 && lon <= -87.5 {
            return "Chicago"
        }
        
        return nil
    }
    
    private func getCityForCanadaCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 43.5 && lat <= 43.9 && lon >= -79.6 && lon <= -79.1 {
            return "Toronto"
        } else if lat >= 45.4 && lat <= 45.7 && lon >= -73.8 && lon <= -73.4 {
            return "Montreal"
        } else if lat >= 49.0 && lat <= 49.4 && lon >= -123.3 && lon <= -122.9 {
            return "Vancouver"
        }
        
        return nil
    }
    
    private func getCityForUKCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 51.3 && lat <= 51.7 && lon >= -0.5 && lon <= 0.3 {
            return "London"
        } else if lat >= 53.3 && lat <= 53.6 && lon >= -2.4 && lon <= -2.1 {
            return "Manchester"
        }
        
        return nil
    }
    
    private func getCityForFranceCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 48.7 && lat <= 49.0 && lon >= 2.1 && lon <= 2.6 {
            return "Paris"
        } else if lat >= 43.2 && lat <= 43.4 && lon >= 5.3 && lon <= 5.5 {
            return "Marseille"
        }
        
        return nil
    }
    
    private func getCityForGermanyCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 52.3 && lat <= 52.7 && lon >= 13.2 && lon <= 13.6 {
            return "Berlin"
        } else if lat >= 48.0 && lat <= 48.3 && lon >= 11.4 && lon <= 11.8 {
            return "Munich"
        }
        
        return nil
    }
    
    private func getCityForItalyCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 41.7 && lat <= 42.0 && lon >= 12.3 && lon <= 12.7 {
            return "Rome"
        } else if lat >= 45.3 && lat <= 45.6 && lon >= 9.0 && lon <= 9.4 {
            return "Milan"
        }
        
        return nil
    }
    
    private func getCityForSpainCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 40.3 && lat <= 40.6 && lon >= -3.8 && lon <= -3.5 {
            return "Madrid"
        } else if lat >= 41.3 && lat <= 41.5 && lon >= 2.0 && lon <= 2.3 {
            return "Barcelona"
        }
        
        return nil
    }
    
    private func getCityForJapanCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= 35.5 && lat <= 35.8 && lon >= 139.5 && lon <= 139.9 {
            return "Tokyo"
        } else if lat >= 34.6 && lat <= 34.8 && lon >= 135.4 && lon <= 135.6 {
            return "Osaka"
        }
        
        return nil
    }
    
    private func getCityForAustraliaCoordinate(_ coordinate: CLLocationCoordinate2D) -> String? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        if lat >= -34.1 && lat <= -33.7 && lon >= 150.9 && lon <= 151.3 {
            return "Sydney"
        } else if lat >= -37.9 && lat <= -37.7 && lon >= 144.8 && lon <= 145.1 {
            return "Melbourne"
        }
        
        return nil
    }
    
    
    private func getUSTimeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
        let lon = coordinate.longitude
        
        if lon >= -125.0 && lon <= -117.0 {
            return TimeZone(identifier: "America/Los_Angeles")
        } else if lon >= -117.0 && lon <= -104.0 {
            return TimeZone(identifier: "America/Denver")
        } else if lon >= -104.0 && lon <= -87.0 {
            return TimeZone(identifier: "America/Chicago")
        } else if lon >= -87.0 && lon <= -66.0 {
            return TimeZone(identifier: "America/New_York")
        }
        
        return TimeZone(identifier: "America/New_York")
    }
    
    private func getCanadaTimeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
        let lon = coordinate.longitude
        
        if lon >= -141.0 && lon <= -120.0 {
            return TimeZone(identifier: "America/Vancouver")
        } else if lon >= -120.0 && lon <= -110.0 {
            return TimeZone(identifier: "America/Edmonton")
        } else if lon >= -110.0 && lon <= -90.0 {
            return TimeZone(identifier: "America/Winnipeg")
        } else if lon >= -90.0 && lon <= -60.0 {
            return TimeZone(identifier: "America/Toronto")
        } else if lon >= -60.0 && lon <= -52.0 {
            return TimeZone(identifier: "America/Halifax")
        }
        
        return TimeZone(identifier: "America/Toronto")
    }
    
    private func getAustraliaTimeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
        let lon = coordinate.longitude
        
        if lon >= 113.0 && lon <= 129.0 {
            return TimeZone(identifier: "Australia/Perth")
        } else if lon >= 129.0 && lon <= 138.0 {
            return TimeZone(identifier: "Australia/Adelaide")
        } else if lon >= 138.0 && lon <= 154.0 {
            return TimeZone(identifier: "Australia/Sydney")
        }
        
        return TimeZone(identifier: "Australia/Sydney")
    }
}


struct CountryInfo {
    let bounds: (Double, Double, Double, Double) // minLat, maxLat, minLon, maxLon
    let country: String
    let city: String?
    let region: String
    let timeZone: TimeZone?
}
