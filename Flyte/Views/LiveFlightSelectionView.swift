import SwiftUI
import CoreLocation

struct LiveFlightSelectionView: View {
    @Binding var selectedFlight: FlightRoute?
    let flightManager: FlightManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = FlightAPIService.shared
    @State private var selectedFlightIndex = 0
    @State private var searchText = ""
    @State private var showingPreloadSheet = false
    @State private var availableFlights: [FlightRoute] = []
    @State private var showingSearchFilters = false
    @State private var departureFilter = ""
    @State private var arrivalFilter = ""
    @State private var airlineFilter = ""
    @State private var showingFlightNumberInput = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if apiService.cachedFlights.isEmpty {
                        emptyStateView
                    } else {
                        flightListView
                    }
                    
                    if !availableFlights.isEmpty {
                        startTrackingButton
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .onAppear {
                loadAvailableFlights()
            }
        }
        .sheet(isPresented: $showingPreloadSheet) {
            PreloadDataView()
        }
        .sheet(isPresented: $showingSearchFilters) {
            SearchFiltersView(
                departureFilter: $departureFilter,
                arrivalFilter: $arrivalFilter,
                airlineFilter: $airlineFilter,
                onApplyFilters: {
                    loadAvailableFlights()
                }
            )
        }
        .sheet(isPresented: $showingFlightNumberInput) {
            FlightNumberInputView(
                onFlightSelected: { flight in
                    selectedFlight = flight
                    showingFlightNumberInput = false
                    dismiss()
                }
            )
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
                
                Button(action: {
                    showingFlightNumberInput = true
                }) {
                    Image(systemName: "airplane.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: {
                    showingPreloadSheet = true
                }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            if !apiService.cachedFlights.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Search flights...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .onChange(of: searchText) { _, _ in
                                loadAvailableFlights()
                            }
                        
                        Button(action: {
                            showingSearchFilters = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    if !departureFilter.isEmpty || !arrivalFilter.isEmpty || !airlineFilter.isEmpty {
                        HStack {
                            if !departureFilter.isEmpty {
                                FilterChip(text: "From: \(departureFilter)", onRemove: {
                                    departureFilter = ""
                                    loadAvailableFlights()
                                })
                            }
                            
                            if !arrivalFilter.isEmpty {
                                FilterChip(text: "To: \(arrivalFilter)", onRemove: {
                                    arrivalFilter = ""
                                    loadAvailableFlights()
                                })
                            }
                            
                            if !airlineFilter.isEmpty {
                                FilterChip(text: "Airline: \(airlineFilter)", onRemove: {
                                    airlineFilter = ""
                                    loadAvailableFlights()
                                })
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                clearAllFilters()
                            }) {
                                Text("Clear All")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "airplane.departure")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.4))
            
            Text("No Flight Data")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Download flight data to get started")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: {
                showingPreloadSheet = true
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Download Data")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(20)
            }
            
            Spacer()
        }
    }
    
    private var flightListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(availableFlights.enumerated()), id: \.offset) { index, flight in
                    LiveFlightCard(
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
    }
    
    private var startTrackingButton: some View {
        Button(action: {
            if !availableFlights.isEmpty {
                let selectedFlight = availableFlights[selectedFlightIndex]
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
            }
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
    
    private func loadAvailableFlights() {
        var flights: [FlightRoute] = []
        
        for flightData in apiService.cachedFlights {
            if let route = apiService.getFlightRoute(from: flightData) {
                flights.append(route)
            }
        }
        
        flights = applyFilters(to: flights)
        availableFlights = flights
    }
    
    private func applyFilters(to flights: [FlightRoute]) -> [FlightRoute] {
        var filteredFlights = flights
        
        if !searchText.isEmpty {
            filteredFlights = filteredFlights.filter { flight in
                flight.departure.code.localizedCaseInsensitiveContains(searchText) ||
                flight.arrival.code.localizedCaseInsensitiveContains(searchText) ||
                flight.airline.localizedCaseInsensitiveContains(searchText) ||
                flight.flightNumber.localizedCaseInsensitiveContains(searchText) ||
                flight.departure.city.localizedCaseInsensitiveContains(searchText) ||
                flight.arrival.city.localizedCaseInsensitiveContains(searchText) ||
                flight.departure.country.localizedCaseInsensitiveContains(searchText) ||
                flight.arrival.country.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if !departureFilter.isEmpty {
            filteredFlights = filteredFlights.filter { flight in
                flight.departure.code.localizedCaseInsensitiveContains(departureFilter) ||
                flight.departure.city.localizedCaseInsensitiveContains(departureFilter) ||
                flight.departure.country.localizedCaseInsensitiveContains(departureFilter)
            }
        }
        
        if !arrivalFilter.isEmpty {
            filteredFlights = filteredFlights.filter { flight in
                flight.arrival.code.localizedCaseInsensitiveContains(arrivalFilter) ||
                flight.arrival.city.localizedCaseInsensitiveContains(arrivalFilter) ||
                flight.arrival.country.localizedCaseInsensitiveContains(arrivalFilter)
            }
        }
        
        if !airlineFilter.isEmpty {
            filteredFlights = filteredFlights.filter { flight in
                flight.airline.localizedCaseInsensitiveContains(airlineFilter)
            }
        }
        
        return filteredFlights
    }
    
    private func clearAllFilters() {
        searchText = ""
        departureFilter = ""
        arrivalFilter = ""
        airlineFilter = ""
        loadAvailableFlights()
    }
}

struct LiveFlightCard: View {
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
                        Text(flight.flightNumber)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
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
                        Text("AIRLINE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text(flight.airline)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("AIRCRAFT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text(flight.aircraft)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text("\(Int(flight.distance)) km")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEPARTURE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text(formatTime(flight.scheduledDeparture))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ARRIVAL")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text(formatTime(flight.scheduledArrival))
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PreloadDataView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = FlightAPIService.shared
    @State private var isPreloading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    headerView
                    
                    VStack(spacing: 20) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Download Flight Data")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Get the latest flight information to use offline during your journey")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    if let lastUpdate = apiService.lastUpdateTime {
                        VStack(spacing: 8) {
                            Text("LAST UPDATE")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                            
                            Text(formatDate(lastUpdate))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    if isPreloading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            
                            Text("Downloading flight data...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        Button(action: {
                            Task {
                                isPreloading = true
                                await apiService.preloadFlightData()
                                isPreloading = false
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Download Data")
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
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
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
            
            Text("DOWNLOAD DATA")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SearchFiltersView: View {
    @Binding var departureFilter: String
    @Binding var arrivalFilter: String
    @Binding var airlineFilter: String
    let onApplyFilters: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    VStack(spacing: 24) {
                        filterSection(
                            title: "DEPARTURE",
                            placeholder: "City, airport code, or country",
                            text: $departureFilter,
                            icon: "airplane.departure"
                        )
                        
                        filterSection(
                            title: "ARRIVAL",
                            placeholder: "City, airport code, or country",
                            text: $arrivalFilter,
                            icon: "airplane.arrival"
                        )
                        
                        filterSection(
                            title: "AIRLINE",
                            placeholder: "Airline name",
                            text: $airlineFilter,
                            icon: "building.2"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    Spacer()
                    
                    Button(action: {
                        onApplyFilters()
                        dismiss()
                    }) {
                        Text("Apply Filters")
                            .font(.system(size: 18, weight: .medium))
                            .tracking(1)
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
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
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
            
            Text("SEARCH FILTERS")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Button(action: {
                departureFilter = ""
                arrivalFilter = ""
                airlineFilter = ""
            }) {
                Text("Clear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func filterSection(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
            }
            
            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

#Preview {
    LiveFlightSelectionView(selectedFlight: .constant(nil), flightManager: FlightManager())
}
