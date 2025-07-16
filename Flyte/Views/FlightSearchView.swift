import SwiftUI
import CoreLocation

struct FlightSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = FlightAPIService.shared
    @State private var searchText = ""
    @State private var selectedSearchType = 0
    @State private var departureSearch = ""
    @State private var arrivalSearch = ""
    @State private var airlineSearch = ""
    @State private var flightNumberSearch = ""
    @State private var searchResults: [FlightData] = []
    @State private var showingFlightDetails = false
    @State private var selectedFlight: FlightData?
    
    private let searchTypes = ["All", "Route", "Airline", "Flight Number"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if apiService.cachedFlights.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 0) {
                            searchSection
                            resultsSection
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .onAppear {
                performSearch()
            }
        }
        .sheet(isPresented: $showingFlightDetails) {
            if let flight = selectedFlight {
                FlightDetailModalView(flightData: flight)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("SEARCH FLIGHTS")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Button(action: {
                clearSearch()
            }) {
                Text("Clear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var searchSection: some View {
        VStack(spacing: 20) {
            Picker("Search Type", selection: $selectedSearchType) {
                ForEach(0..<searchTypes.count, id: \.self) { index in
                    Text(searchTypes[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .onChange(of: selectedSearchType) { _, _ in
                performSearch()
            }
            
            Group {
                switch selectedSearchType {
                case 0: // All
                    generalSearchView
                case 1: // Route
                    routeSearchView
                case 2: // Airline
                    airlineSearchView
                case 3: // Flight Number
                    flightNumberSearchView
                default:
                    generalSearchView
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    private var generalSearchView: some View {
        VStack(spacing: 16) {
            SearchField(
                placeholder: "Search flights, airports, airlines...",
                text: $searchText,
                icon: "magnifyingglass"
            )
            .onChange(of: searchText) { _, _ in
                performSearch()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var routeSearchView: some View {
        VStack(spacing: 16) {
            SearchField(
                placeholder: "Departure (JFK, New York, etc.)",
                text: $departureSearch,
                icon: "airplane.departure"
            )
            .onChange(of: departureSearch) { _, _ in
                performSearch()
            }
            
            SearchField(
                placeholder: "Arrival (LHR, London, etc.)",
                text: $arrivalSearch,
                icon: "airplane.arrival"
            )
            .onChange(of: arrivalSearch) { _, _ in
                performSearch()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var airlineSearchView: some View {
        VStack(spacing: 16) {
            SearchField(
                placeholder: "Airline name or code",
                text: $airlineSearch,
                icon: "building.2"
            )
            .onChange(of: airlineSearch) { _, _ in
                performSearch()
            }
            
            if !apiService.getUniqueAirlines().isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(apiService.getUniqueAirlines().prefix(10), id: \.self) { airline in
                            Button(action: {
                                airlineSearch = airline
                                performSearch()
                            }) {
                                Text(airline)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var flightNumberSearchView: some View {
        VStack(spacing: 16) {
            SearchField(
                placeholder: "Flight number (BA178, JL62, etc.)",
                text: $flightNumberSearch,
                icon: "airplane"
            )
            .onChange(of: flightNumberSearch) { _, _ in
                performSearch()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RESULTS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                
                Spacer()
                
                Text("\(searchResults.count) flights")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            
            if searchResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("No flights found")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Try adjusting your search criteria")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.flight.iata) { flight in
                            SearchResultCard(flightData: flight) {
                                selectedFlight = flight
                                showingFlightDetails = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.4))
            
            Text("No Flight Data")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Download flight data to search for flights")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
    }
    
    private func performSearch() {
        switch selectedSearchType {
        case 0: // All
            if searchText.isEmpty {
                searchResults = Array(apiService.cachedFlights.prefix(50))
            } else {
                searchResults = apiService.searchFlights(
                    departure: searchText,
                    arrival: searchText,
                    airline: searchText,
                    flightNumber: searchText
                )
            }
        case 1: // Route
            searchResults = apiService.searchFlights(
                departure: departureSearch,
                arrival: arrivalSearch
            )
        case 2: // Airline
            searchResults = apiService.searchFlights(airline: airlineSearch)
        case 3: // Flight Number
            if let flight = apiService.getFlightStatus(flightNumber: flightNumberSearch) {
                searchResults = [flight]
            } else {
                searchResults = []
            }
        default:
            searchResults = []
        }
    }
    
    private func clearSearch() {
        searchText = ""
        departureSearch = ""
        arrivalSearch = ""
        airlineSearch = ""
        flightNumberSearch = ""
        searchResults = []
        selectedSearchType = 0
    }
}

struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SearchResultCard: View {
    let flightData: FlightData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flightData.departure.iata)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(flightData.departure.airport)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(flightData.flight.iata)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "airplane")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(flightData.arrival.iata)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(flightData.arrival.airport)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                HStack {
                    Text(flightData.airline.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(flightData.flight_status.uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(statusColor(flightData.flight_status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(flightData.flight_status).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "scheduled":
            return .green
        case "landed":
            return .blue
        case "cancelled":
            return .red
        case "delayed":
            return .orange
        default:
            return .gray
        }
    }
}

struct FlightDetailModalView: View {
    let flightData: FlightData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Text("FLIGHT DETAILS")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            flightHeaderSection
                            routeSection
                            timingSection
                            if let aircraft = flightData.aircraft {
                                aircraftSection(aircraft)
                            }
                            if let live = flightData.live {
                                liveSection(live)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
    
    private var flightHeaderSection: some View {
        VStack(spacing: 16) {
            Text("\(flightData.airline.name) \(flightData.flight.iata)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(flightData.flight_status.uppercased())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor(flightData.flight_status))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(statusColor(flightData.flight_status).opacity(0.2))
                .cornerRadius(16)
        }
    }
    
    private var routeSection: some View {
        VStack(spacing: 16) {
            Text("ROUTE")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(flightData.departure.iata)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text(flightData.departure.airport)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(flightData.arrival.iata)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text(flightData.arrival.airport)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var timingSection: some View {
        VStack(spacing: 16) {
            Text("TIMING")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            HStack {
                timingCard(title: "DEPARTURE", time: flightData.departure.scheduled)
                Spacer()
                timingCard(title: "ARRIVAL", time: flightData.arrival.scheduled)
            }
        }
    }
    
    private func timingCard(title: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
            
            Text(formatTime(time))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func aircraftSection(_ aircraft: AircraftInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AIRCRAFT")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            if let registration = aircraft.registration {
                Text("Registration: \(registration)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if let iata = aircraft.iata {
                Text("Aircraft: \(iata)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func liveSection(_ live: LiveInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIVE DATA")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            if let lat = live.latitude, let lng = live.longitude {
                Text("Position: \(lat, specifier: "%.4f")°, \(lng, specifier: "%.4f")°")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if let altitude = live.altitude {
                Text("Altitude: \(Int(altitude)) ft")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if let speed = live.speed_horizontal {
                Text("Speed: \(Int(speed)) km/h")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "scheduled":
            return .green
        case "landed":
            return .blue
        case "cancelled":
            return .red
        case "delayed":
            return .orange
        default:
            return .gray
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: timeString) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        }
        return timeString
    }
}

#Preview {
    FlightSearchView()
}
