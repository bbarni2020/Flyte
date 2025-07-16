import SwiftUI

struct LoadingView: View {
    @State private var isRotating = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isRotating)
                
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.4))
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scale)
            }
            
            VStack(spacing: 8) {
                Text("Loading...")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                
                Text("Please wait while we fetch your flight data")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            isRotating = true
            scale = 1.1
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
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isPulsing ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isPulsing
                        )
                }
            }
            
            Text("Processing...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
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
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .frame(width: 180, height: 80)
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(spacing: 4) {
                            Text("LAX")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("JFK")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    
                    HStack {
                        Spacer()
                        
                        Image(systemName: "airplane")
                            .font(.system(size: 14, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.4))
                            .rotationEffect(.degrees(45))
                            .rotationEffect(.degrees(isFlying ? 2 : -2))
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isFlying)
                            .offset(x: animationProgress * 120 - 60)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Text("Preparing your flight data...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: true)) {
                animationProgress = 1.0
            }
            isFlying = true
        }
    }
}
