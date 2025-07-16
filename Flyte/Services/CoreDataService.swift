//
//  CoreDataService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import CoreData
import CoreLocation

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FlightDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func saveFlight(_ flight: SavedFlight) {
        let entity = flight.toFlightEntity(context: context)
        save()
    }
    
    func loadFlights() -> [SavedFlight] {
        let request: NSFetchRequest<FlightEntity> = FlightEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FlightEntity.departureTime, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toSavedFlight() }
        } catch {
            print("Failed to fetch flights: \(error)")
            return []
        }
    }
    
    func deleteFlight(_ flight: SavedFlight) {
        let request: NSFetchRequest<FlightEntity> = FlightEntity.fetchRequest()
        request.predicate = NSPredicate(format: "flightNumber == %@", flight.flightNumber)
        
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            save()
        } catch {
            print("Failed to delete flight: \(error)")
        }
    }
    
    func updateFlight(_ flight: SavedFlight) {
        let request: NSFetchRequest<FlightEntity> = FlightEntity.fetchRequest()
        request.predicate = NSPredicate(format: "flightNumber == %@", flight.flightNumber)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                entity.gate = flight.gate
                entity.terminal = flight.terminal
                entity.baggageReclaim = flight.baggageReclaim
                entity.status = flight.status.rawValue
                entity.aircraft = flight.aircraft
                entity.isDownloaded = flight.isDownloaded
                
                if let routeData = flight.routeData {
                    entity.routeWaypoints = try? JSONEncoder().encode(routeData.waypoints)
                    entity.routeDuration = routeData.duration
                    entity.routeDistance = routeData.distance
                    entity.offlineMapData = routeData.offlineMapData
                }
                
                save()
            }
        } catch {
            print("Failed to update flight: \(error)")
        }
    }
    
    func saveFlightCache(_ cache: FlightTrackingCache) {
        let entity = FlightCacheEntity(context: context)
        entity.flightNumber = cache.flightNumber
        entity.icao24 = cache.icao24
        entity.lastUpdate = cache.lastUpdate
        entity.apiSource = cache.apiSource
        
        if let position = cache.lastKnownPosition {
            entity.lastLatitude = position.latitude
            entity.lastLongitude = position.longitude
        }
        
        save()
    }
    
    func loadFlightCache(for flightNumber: String) -> FlightTrackingCache? {
        let request: NSFetchRequest<FlightCacheEntity> = FlightCacheEntity.fetchRequest()
        request.predicate = NSPredicate(format: "flightNumber == %@", flightNumber)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FlightCacheEntity.lastUpdate, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            return entities.first?.toFlightTrackingCache()
        } catch {
            print("Failed to load flight cache: \(error)")
            return nil
        }
    }
}


@objc(FlightEntity)
public class FlightEntity: NSManagedObject {
    @NSManaged public var flightNumber: String
    @NSManaged public var departureDate: Date
    @NSManaged public var departureTime: Date
    @NSManaged public var gate: String?
    @NSManaged public var terminal: String?
    @NSManaged public var baggageReclaim: String?
    @NSManaged public var status: String
    @NSManaged public var departureAirportCode: String
    @NSManaged public var arrivalAirportCode: String
    @NSManaged public var airline: String
    @NSManaged public var aircraft: String?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var routeWaypoints: Data?
    @NSManaged public var routeDuration: TimeInterval
    @NSManaged public var routeDistance: Double
    @NSManaged public var offlineMapData: Data?
    
    func toSavedFlight() -> SavedFlight? {
        return nil
    }
}

@objc(FlightCacheEntity)
public class FlightCacheEntity: NSManagedObject {
    @NSManaged public var flightNumber: String
    @NSManaged public var icao24: String?
    @NSManaged public var lastLatitude: Double
    @NSManaged public var lastLongitude: Double
    @NSManaged public var lastUpdate: Date
    @NSManaged public var apiSource: String
    
    func toFlightTrackingCache() -> FlightTrackingCache {
        let position = CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
        return FlightTrackingCache(
            flightNumber: flightNumber,
            icao24: icao24,
            lastKnownPosition: position,
            lastUpdate: lastUpdate,
            apiSource: apiSource
        )
    }
}

extension FlightEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlightEntity> {
        return NSFetchRequest<FlightEntity>(entityName: "FlightEntity")
    }
}

extension FlightCacheEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlightCacheEntity> {
        return NSFetchRequest<FlightCacheEntity>(entityName: "FlightCacheEntity")
    }
}
