//
//  KeychainService.swift
//  Flyte
//
//  Created by Balogh Barnabás on 2025. 07. 17..
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.flyte.app"
    
    private init() {}
    
    
    func saveAPIKey(_ apiKey: String, for service: APIService) {
        let key = keyForService(service)
        save(apiKey, forKey: key)
    }
    
    func getAPIKey(for service: APIService) -> String? {
        let key = keyForService(service)
        return load(forKey: key)
    }
    
    func deleteAPIKey(for service: APIService) {
        let key = keyForService(service)
        delete(forKey: key)
    }
    
    
    private func keyForService(_ service: APIService) -> String {
        switch service {
        case .aviationStack:
            return "aviationstack_api_key"
        case .mapbox:
            return "mapbox_api_key"
        }
    }
    
    private func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to save to keychain: \(status)")
        }
    }
    
    private func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        guard let data = item as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}


enum APIService {
    case aviationStack
    case mapbox
}
