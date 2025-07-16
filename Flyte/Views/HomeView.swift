import SwiftUI

struct HomeView: View {
    @StateObject private var flightManager = FlightManager()
    @State private var showingAddFlight = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        headerView
                        
                        if isLoading {
                            FlightLoadingView()
                                .frame(height: 200)
                        } else if flightManager.savedFlights.isEmpty {
                            emptyStateView
                        } else {
                            flightsList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Flights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFlight = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView(flightManager: flightManager)
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Track your upcoming flights")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No flights yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Add your first flight to get started")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Button("Add Flight") {
                showingAddFlight = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var flightsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(flightManager.savedFlights) { flight in
                FlightCardView(flight: flight, flightManager: flightManager)
            }
        }
    }
}

struct FlightCardView: View {
    let flight: SavedFlight
    let flightManager: FlightManager
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(flight.airline)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(flight.departureDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(flight.departureTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FROM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(flight.departure.code)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(flight.departure.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TO")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(flight.arrival.code)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(flight.arrival.city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            HStack(spacing: 16) {
                if let gate = flight.gate {
                    InfoPill(title: "Gate", value: gate, color: .blue)
                }
                
                InfoPill(title: "Status", value: flight.status.rawValue, color: Color(flight.status.color))
                
                if let baggage = flight.baggageReclaim {
                    InfoPill(title: "Baggage", value: baggage, color: .green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            HStack(spacing: 12) {
                Button(action: { downloadRoute() }) {
                    HStack {
                        Image(systemName: flight.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                        Text(flight.isDownloaded ? "Downloaded" : "Download")
                    }
                    .font(.caption)
                    .foregroundColor(flight.isDownloaded ? .green : .blue)
                }
                .disabled(flight.isDownloaded)
                
                Spacer()
                
                Button("Track Flight") {
                    flightManager.startTracking(flight: flight)
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func downloadRoute() {
        flightManager.downloadRouteData(for: flight)
    }
}

struct InfoPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AddFlightView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var flightManager: FlightManager
    
    @State private var flightNumber = ""
    @State private var departureDate = Date()
    @State private var departureTime = Date()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if isLoading {
                        FlightLoadingView()
                            .frame(height: 200)
                    } else {
                        formContent
                    }
                }
                .padding()
            }
            .navigationTitle("Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFlight()
                    }
                    .foregroundColor(.white)
                    .disabled(flightNumber.isEmpty)
                }
            }
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Flight Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Flight Number")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("e.g., AA123", text: $flightNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Departure Date")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    DatePicker("", selection: $departureDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Departure Time")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    DatePicker("", selection: $departureTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            
            Spacer()
        }
    }
    
    private func addFlight() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            flightManager.addFlight(
                flightNumber: flightNumber,
                departureDate: departureDate,
                departureTime: departureTime
            )
            isLoading = false
            dismiss()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
