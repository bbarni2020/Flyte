import SwiftUI

struct APISetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var showingInstructions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    headerView
                    
                    VStack(spacing: 20) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("API Setup")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Enter your AviationStack API key to get real flight data")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    VStack(spacing: 16) {
                        TextField("Enter API Key", text: $apiKey)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        
                        Button(action: {
                            showingInstructions = true
                        }) {
                            Text("How to get API key?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        saveAPIKey()
                        dismiss()
                    }) {
                        Text("Save API Key")
                            .font(.system(size: 18, weight: .medium))
                            .tracking(1)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(apiKey.isEmpty ? Color.gray : Color.white)
                            .cornerRadius(28)
                    }
                    .disabled(apiKey.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingInstructions) {
            APIInstructionsView()
        }
        .onAppear {
            loadSavedAPIKey()
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
            
            Text("API SETUP")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: "aviationstack_api_key")
    }
    
    private func loadSavedAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: "aviationstack_api_key") ?? ""
    }
}

struct APIInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    headerView
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            instructionStep(
                                number: "1",
                                title: "Visit AviationStack",
                                description: "Go to aviationstack.com and create a free account"
                            )
                            
                            instructionStep(
                                number: "2",
                                title: "Get Free API Key",
                                description: "Sign up for the free plan (1000 requests/month)"
                            )
                            
                            instructionStep(
                                number: "3",
                                title: "Copy API Key",
                                description: "Copy your API key from the dashboard"
                            )
                            
                            instructionStep(
                                number: "4",
                                title: "Paste in App",
                                description: "Enter the API key in the previous screen"
                            )
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Free Plan Includes:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    bulletPoint("1,000 API requests per month")
                                    bulletPoint("Real-time flight data")
                                    bulletPoint("Historical flight information")
                                    bulletPoint("Airport data")
                                }
                            }
                            .padding(.top, 20)
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
            
            Text("API INSTRUCTIONS")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    private func instructionStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(number)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    APISetupView()
}
