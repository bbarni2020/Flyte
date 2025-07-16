import SwiftUI

struct LoadingView: View {
    @State private var isRotating = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
                
                Image(systemName: "airplane")
                    .font(.title2)
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scale)
            }
            
            VStack(spacing: 8) {
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Please wait while we fetch your flight data")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            isRotating = true
            scale = 1.2
        }
        .onDisappear {
            isRotating = false
            scale = 1.0
        }
    }
}

struct PulsingLoadingView: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .scaleEffect(isPulsing ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isPulsing
                        )
                }
            }
            
            Text("Processing...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            isPulsing = true
        }
    }
}

struct FlightLoadingView: View {
    @State private var animationProgress: CGFloat = 0
    @State private var isFlying = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 100)
                
                HStack {
                    VStack {
                        Text("LAX")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("JFK")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal, 30)
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal, 30)
                
                HStack {
                    Spacer()
                    
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isFlying ? 5 : -5))
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isFlying)
                        .offset(x: animationProgress * 140 - 70)
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            
            Text("Preparing your flight data...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                animationProgress = 1.0
            }
            isFlying = true
        }
    }
}
