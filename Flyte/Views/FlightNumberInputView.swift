import SwiftUI
import CoreLocation

struct FlightNumberInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = FlightAPIService.shared
    @State private var flightNumber = ""
    @State private var isSearching = false
    @State private var searchResult: FlightData?
    @State private var errorMessage = ""
    @State private var showingFlightDetails = false
    
    let onFlightSelected: (FlightRoute) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    VStack(spacing: 30) {
                        instructionSection
                        
                        inputSection
                        
                        if isSearching {
                            searchingView
                        } else if let result = searchResult {
                            resultSection(result)
                        } else if !errorMessage.isEmpty {
                            errorSection
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingFlightDetails) {
            if let result = searchResult {
                FlightDetailModalView(flightData: result)
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
            
            Text("FLIGHT LOOKUP")
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
    
    private var instructionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Enter Your Flight Number")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            Text("Find and download your specific flight route using the flight number from your boarding pass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "airplane")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("FLIGHT NUMBER")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                }
                
                TextField("e.g., BA178, JL62, LH400", text: $flightNumber)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            }
            
            Button(action: {
                searchForFlight()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                    Text("Search Flight")
                        .font(.system(size: 18, weight: .medium))
                        .tracking(1)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(flightNumber.isEmpty ? Color.gray : Color.white)
                .cornerRadius(28)
            }
            .disabled(flightNumber.isEmpty || isSearching)
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            
            Text("Searching for flight \(flightNumber)...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 30)
    }
    
    private func resultSection(_ result: FlightData) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Flight Found!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                FlightSummaryCard(flightData: result)
                
                HStack(spacing: 12) {
                    Button(action: {
                        showingFlightDetails = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14, weight: .medium))
                            Text("View Details")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(24)
                    }
                    
                    Button(action: {
                        selectFlight(result)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Track This Flight")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(24)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    private var errorSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.orange)
            
            Text("Flight Not Found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.orange)
            
            Text(errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                clearSearch()
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 20)
    }
    
    private func searchForFlight() {
        guard !flightNumber.isEmpty else { return }
        
        isSearching = true
        errorMessage = ""
        searchResult = nil
        
        if let cachedResult = apiService.getFlightStatus(flightNumber: flightNumber) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.searchResult = cachedResult
                self.isSearching = false
            }
            return
        }
        
        Task {
            await searchFlightFromAPI()
        }
    }
    
    private func searchFlightFromAPI() async {
        guard !apiService.apiKey.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "API key not configured. Please set up your API key in settings."
                self.isSearching = false
            }
            return
        }
        
        guard let url = URL(string: "https://api.aviationstack.com/v1/flights?access_key=\(apiService.apiKey)&flight_iata=\(flightNumber)") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid flight number format"
                self.isSearching = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let apiResponse = try JSONDecoder().decode(FlightAPIResponse.self, from: data)
            
            await MainActor.run {
                if let flight = apiResponse.data.first {
                    self.searchResult = flight
                    self.apiService.cachedFlights.append(flight)
                    self.apiService.saveCachedData()
                } else {
                    self.errorMessage = "Flight \(self.flightNumber) not found. Please check the flight number and try again."
                }
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unable to search for flight. Please check your connection and try again."
                self.isSearching = false
            }
        }
    }
    
    private func selectFlight(_ flightData: FlightData) {
        if let route = apiService.getFlightRoute(from: flightData) {
            onFlightSelected(route)
            dismiss()
        } else {
            errorMessage = "Unable to create route for this flight. Missing airport information."
        }
    }
    
    private func clearSearch() {
        flightNumber = ""
        searchResult = nil
        errorMessage = ""
        isSearching = false
    }
}

struct FlightSummaryCard: View {
    let flightData: FlightData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flightData.departure.iata)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(flightData.departure.airport)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(flightData.flight.iata)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "airplane")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(flightData.arrival.iata)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(flightData.arrival.airport)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AIRLINE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    Text(flightData.airline.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("STATUS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                    Text(flightData.flight_status.uppercased())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statusColor(flightData.flight_status))
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
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

#Preview {
    FlightNumberInputView { _ in }
}
