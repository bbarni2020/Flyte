import SwiftUI

struct HomeView: View {
    @StateObject private var flightManager = FlightManager()
    @State private var showingAddFlight = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
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
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView(flightManager: flightManager)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FLYTE")
                        .font(.system(size: 20, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(6)
                    
                    Text("Flight Tracker")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                Spacer()
                
                Button(action: { showingAddFlight = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            if !flightManager.savedFlights.isEmpty {
                Text("MY FLIGHTS")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
                    .padding(.top, 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No flights yet")
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Text("Add your first flight to get started")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1)
            }
            
            Button("Add Flight") {
                showingAddFlight = true
            }
            .buttonStyle(MinimalButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var flightsList: some View {
        LazyVStack(spacing: 16) {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(flight.flightNumber)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text(flight.airline)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(flight.departureDate, style: .date)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(0.5)
                    
                    Text(flight.departureTime, style: .time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FROM")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                    Text(flight.departure.code)
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundColor(.white)
                        .tracking(2)
                    Text(flight.departure.city)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(0.5)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.3))
                    .rotationEffect(.degrees(45))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("TO")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                    Text(flight.arrival.code)
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundColor(.white)
                        .tracking(2)
                    Text(flight.arrival.city)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            HStack(spacing: 12) {
                if let gate = flight.gate {
                    MinimalInfoPill(title: "Gate", value: gate)
                }
                
                MinimalInfoPill(title: "Status", value: flight.status.rawValue)
                
                if let baggage = flight.baggageReclaim {
                    MinimalInfoPill(title: "Baggage", value: baggage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            HStack(spacing: 16) {
                Button(action: { downloadRoute() }) {
                    HStack(spacing: 6) {
                        Image(systemName: flight.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 12, weight: .medium))
                        Text(flight.isDownloaded ? "Downloaded" : "Download")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.5)
                    }
                    .foregroundColor(flight.isDownloaded ? .white.opacity(0.4) : .white.opacity(0.6))
                }
                .disabled(flight.isDownloaded)
                
                Spacer()
                
                Button("Track Flight") {
                    flightManager.startTracking(flight: flight)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black)
                .tracking(1)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private func downloadRoute() {
        flightManager.downloadRouteData(for: flight)
    }
}

struct MinimalInfoPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1)
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
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
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    headerView
                    
                    if isLoading {
                        FlightLoadingView()
                            .frame(height: 200)
                    } else {
                        formContent
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
            .tracking(0.5)
            
            Spacer()
            
            Text("ADD FLIGHT")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .tracking(3)
            
            Spacer()
            
            Button("Add") {
                addFlight()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(flightNumber.isEmpty ? .white.opacity(0.3) : .white)
            .tracking(0.5)
            .disabled(flightNumber.isEmpty)
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FLIGHT NUMBER")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                    
                    TextField("e.g., AA123", text: $flightNumber)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEPARTURE DATE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                    
                    DatePicker("", selection: $departureDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEPARTURE TIME")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                    
                    DatePicker("", selection: $departureTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
            }
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

// MARK: - Button Styles

struct MinimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .tracking(2)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(24)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
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
