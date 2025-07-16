import SwiftUI
import CoreLocation

struct FlightSelectionView: View {
    @Binding var selectedFlight: FlightRoute?
    let flightManager: FlightManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFlightIndex = 0
    
    private let sampleFlights = [
        FlightRoute(
            departure: Airport(code: "JFK", name: "John F. Kennedy International", city: "New York", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)),
            arrival: Airport(code: "LHR", name: "London Heathrow", city: "London", country: "UK", coordinate: CLLocationCoordinate2D(latitude: 51.4700, longitude: -0.4543)),
            waypoints: [],
            duration: 25200,
            distance: 3459,
            flightNumber: "BA178",
            airline: "British Airways",
            aircraft: "Boeing 777",
            scheduledDeparture: Date().addingTimeInterval(3600),
            scheduledArrival: Date().addingTimeInterval(28800)
        ),
        FlightRoute(
            departure: Airport(code: "LAX", name: "Los Angeles International", city: "Los Angeles", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 33.9425, longitude: -118.4081)),
            arrival: Airport(code: "NRT", name: "Tokyo Narita", city: "Tokyo", country: "Japan", coordinate: CLLocationCoordinate2D(latitude: 35.7647, longitude: 140.3864)),
            waypoints: [],
            duration: 39600,
            distance: 5434,
            flightNumber: "JL62",
            airline: "Japan Airlines",
            aircraft: "Boeing 787",
            scheduledDeparture: Date().addingTimeInterval(7200),
            scheduledArrival: Date().addingTimeInterval(46800)
        ),
        FlightRoute(
            departure: Airport(code: "CDG", name: "Charles de Gaulle", city: "Paris", country: "France", coordinate: CLLocationCoordinate2D(latitude: 49.0097, longitude: 2.5479)),
            arrival: Airport(code: "SYD", name: "Sydney Kingsford Smith", city: "Sydney", country: "Australia", coordinate: CLLocationCoordinate2D(latitude: -33.9399, longitude: 151.1753)),
            waypoints: [],
            duration: 73800,
            distance: 10564,
            flightNumber: "QF32",
            airline: "Qantas",
            aircraft: "Airbus A380",
            scheduledDeparture: Date().addingTimeInterval(5400),
            scheduledArrival: Date().addingTimeInterval(79200)
        ),
        FlightRoute(
            departure: Airport(code: "DXB", name: "Dubai International", city: "Dubai", country: "UAE", coordinate: CLLocationCoordinate2D(latitude: 25.2532, longitude: 55.3657)),
            arrival: Airport(code: "JFK", name: "John F. Kennedy International", city: "New York", country: "USA", coordinate: CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)),
            waypoints: [],
            duration: 50400,
            distance: 6836,
            flightNumber: "EK204",
            airline: "Emirates",
            aircraft: "Boeing 777",
            scheduledDeparture: Date().addingTimeInterval(1800),
            scheduledArrival: Date().addingTimeInterval(52200)
        ),
        FlightRoute(
            departure: Airport(code: "FRA", name: "Frankfurt Airport", city: "Frankfurt", country: "Germany", coordinate: CLLocationCoordinate2D(latitude: 50.0379, longitude: 8.5622)),
            arrival: Airport(code: "SIN", name: "Singapore Changi", city: "Singapore", country: "Singapore", coordinate: CLLocationCoordinate2D(latitude: 1.3644, longitude: 103.9915)),
            waypoints: [],
            duration: 46800,
            distance: 6472,
            flightNumber: "LH778",
            airline: "Lufthansa",
            aircraft: "Airbus A350",
            scheduledDeparture: Date().addingTimeInterval(10800),
            scheduledArrival: Date().addingTimeInterval(57600)
        ),
        FlightRoute(
            departure: Airport(code: "YYZ", name: "Toronto Pearson", city: "Toronto", country: "Canada", coordinate: CLLocationCoordinate2D(latitude: 43.6777, longitude: -79.6248)),
            arrival: Airport(code: "FCO", name: "Rome Fiumicino", city: "Rome", country: "Italy", coordinate: CLLocationCoordinate2D(latitude: 41.8003, longitude: 12.2389)),
            waypoints: [],
            duration: 32400,
            distance: 4281,
            flightNumber: "AC872",
            airline: "Air Canada",
            aircraft: "Boeing 787",
            scheduledDeparture: Date().addingTimeInterval(14400),
            scheduledArrival: Date().addingTimeInterval(46800)
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(sampleFlights.enumerated()), id: \.offset) { index, flight in
                                FlightCard(
                                    flight: flight,
                                    isSelected: selectedFlightIndex == index,
                                    onTap: {
                                        selectedFlightIndex = index
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    startTrackingButton
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("SELECT FLIGHT")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .tracking(2)
                
                Spacer()
                
                Color.clear.frame(width: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var startTrackingButton: some View {
        Button(action: {
            let selectedFlight = sampleFlights[selectedFlightIndex]
            flightManager.startTracking(flight: SavedFlight(
                flightNumber: selectedFlight.flightNumber,
                departureDate: selectedFlight.scheduledDeparture,
                departureTime: selectedFlight.scheduledDeparture,
                departure: selectedFlight.departure,
                arrival: selectedFlight.arrival,
                airline: selectedFlight.airline,
                aircraft: selectedFlight.aircraft
            ))
            dismiss()
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Start Tracking")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(1)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(28)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

struct FlightCard: View {
    let flight: FlightRoute
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flight.departure.code)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(flight.departure.city)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(formatDuration(flight.duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(flight.arrival.code)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(flight.arrival.city)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text("\(Int(flight.distance)) mi")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ROUTE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text("\(flight.departure.country) → \(flight.arrival.country)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    FlightSelectionView(selectedFlight: .constant(nil), flightManager: FlightManager())
}
