//
//  APIKeySetupView.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import SwiftUI

struct APIKeySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationMessage = ""
    @State private var showingSuccess = false
    
    @ObservedObject private var apiService = FlightAPIService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerView
                        apiKeyInput
                        instructionsView
                        actionButtons
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            apiKey = apiService.apiKey
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("API Configuration")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Save") {
                    saveAPIKey()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .disabled(apiKey.isEmpty || isValidating)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("AVIATIONSTACK API")
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundColor(.white)
                    .tracking(6)
                
                Text("Configure your API key for detailed flight information")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var apiKeyInput: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "key")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("API KEY")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                TextField("Enter your AviationStack API key", text: $apiKey)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
            
            if !validationMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: showingSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(showingSuccess ? .green : .red)
                    
                    Text(validationMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(showingSuccess ? .green : .red)
                }
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("HOW TO GET YOUR API KEY")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    instructionStep(number: "1", text: "Visit aviationstack.com")
                    instructionStep(number: "2", text: "Create a free account")
                    instructionStep(number: "3", text: "Copy your API key from the dashboard")
                    instructionStep(number: "4", text: "Paste it above and save")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("USAGE LIMITS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Free Plan:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("100 requests/month")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    HStack {
                        Text("Current Usage:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(apiService.requestCount)/\(apiService.requestLimit)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    ProgressView(value: Double(apiService.requestCount), total: Double(apiService.requestLimit))
                        .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.6)))
                        .scaleEffect(y: 0.5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: saveAPIKey) {
                HStack {
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isValidating ? "Validating..." : "Save API Key")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(12)
            }
            .disabled(apiKey.isEmpty || isValidating)
            
            if !apiKey.isEmpty {
                Button(action: testAPIKey) {
                    HStack {
                        Image(systemName: "network")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Test Connection")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .disabled(isValidating)
            }
        }
    }
    
    private func instructionStep(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isValidating = true
        validationMessage = ""
        showingSuccess = false
        
        apiService.updateAPIKey(apiKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isValidating = false
            validationMessage = "API key saved successfully"
            showingSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
    
    private func testAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isValidating = true
        validationMessage = ""
        showingSuccess = false
        
        Task {
            await apiService.preloadFlightData()
            
            await MainActor.run {
                isValidating = false
                if apiService.hasValidAPIKey {
                    validationMessage = "Connection successful"
                    showingSuccess = true
                } else {
                    validationMessage = "Invalid API key or connection failed"
                    showingSuccess = false
                }
            }
        }
    }
}

#Preview {
    APIKeySetupView()
}
