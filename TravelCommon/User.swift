//
//  User.swift
//  TravelCommon
//
//  Created by Rohit T P on 14/06/25.
//

//
//  User.swift
//  TravelCommon
//
//  Created by Rohit T P on 14/06/25.
//

import Foundation
import CoreLocation
import AppTrackingTransparency
import AdSupport


public class User: NSObject, Codable {
    // MARK: - Properties
    public private(set) var userId: String?
    public private(set) var language: String
    public private(set) var country: String
    public private(set) var lastUpdated: Date
    
    // Custom preferences
    public var customLanguage: String?
    public var customCountry: String?
    
    // MARK: - Singleton
    public static let shared = User()
    
    // MARK: - Storage Keys
    private enum StorageKeys {
        static let userDefaults = "com.travelcommon.user"
        static let keychainUserId = "com.travelcommon.user.id"
    }
    
    // MARK: - Initialization
    private override init() {
        // Set defaults from system
        self.language = User.detectSystemLanguage()
        self.country = User.detectSystemCountry()
        self.lastUpdated = Date()
        
        super.init()
        
        // Load persisted data
        loadPersistedData()
        
        // Listen for locale changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(localeDidChange),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Set or update the user ID
    public func setUserId(_ userId: String?) {
        self.userId = userId
        saveToKeychain(userId: userId)
        save()
    }
    
    /// Get the effective language (custom or system)
    public func getEffectiveLanguage() -> String {
        return customLanguage ?? language
    }
    
    /// Get the effective country (custom or system)
    public func getEffectiveCountry() -> String {
        return customCountry ?? country
    }
    
    public func getUserId() throws -> String? {
        // Ensure user id
        guard !userId!.isEmpty else { throw NSError(domain: "com.travelcommon.user", code: 1001, userInfo: nil) }
        return userId!
    }
    
    /// Update custom language preference
    public func setCustomLanguage(_ language: String?) {
        self.customLanguage = language
        save()
    }
    
    /// Update custom country preference
    public func setCustomCountry(_ country: String?) {
        self.customCountry = country
        save()
    }
    
    /// Force refresh system preferences
    public func refreshSystemPreferences() {
        self.language = User.detectSystemLanguage()
        self.country = User.detectSystemCountry()
        self.lastUpdated = Date()
        save()
    }
    
    /// Update country based on location (requires location permissions)
    public func updateCountryFromLocation(completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let locationManager = CLLocationManager()
        
        guard CLLocationManager.locationServicesEnabled(),
              let location = locationManager.location else {
            completion(nil)
            return
        }
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let country = placemarks?.first?.isoCountryCode?.lowercased() else {
                completion(nil)
                return
            }
            
            self?.country = country
            self?.lastUpdated = Date()
            self?.save()
            completion(country)
        }
    }
    
    /// Clear all user data
    public func clearUserData() {
        userId = nil
        customLanguage = nil
        customCountry = nil
        deleteFromKeychain()
        UserDefaults.standard.removeObject(forKey: StorageKeys.userDefaults)
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func getIDFA() async -> String? {
        // Check if we have permission to use IDFA
        let status = ATTrackingManager.trackingAuthorizationStatus
        
        switch status {
        case .authorized:
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            // Check if IDFA is not all zeros (which means it's not available)
            if idfa != "00000000-0000-0000-0000-000000000000" {
                return idfa
            }
        case .notDetermined:
            // Request permission
            let granted = await ATTrackingManager.requestTrackingAuthorization()
            if granted == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                if idfa != "00000000-0000-0000-0000-000000000000" {
                    return idfa
                }
            }
        default:
            break
        }
        
        return nil
    }
    
    private static func detectSystemLanguage() -> String {
        // Get the preferred language code
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        // Extract language code (e.g., "en" from "en-US")
        let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? "en"
        
        return languageCode.lowercased()
    }
    
    private static func detectSystemCountry() -> String {
        // Primary: Try to get country from current locale
        if let regionCode = Locale.current.region?.identifier {
            return regionCode.lowercased()
        }
        
        // Fallback 1: Try to get from preferred languages
        // Sometimes the region is embedded in the language identifier
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            if let regionCode = locale.region?.identifier {
                return regionCode.lowercased()
            }
        }
        
        // Fallback 2: Try to infer from timezone
        let timeZone = TimeZone.current
        if let countryCode = countryCodeFromTimeZone(timeZone.identifier) {
            return countryCode.lowercased()
        }
        
        // Fallback 3: Try to get from locale identifier
        let localeIdentifier = Locale.current.identifier
        let components = localeIdentifier.split(separator: "_")
        if components.count > 1,
           let lastComponent = components.last,
           lastComponent.count == 2 {
            return String(lastComponent).lowercased()
        }
        
        // Default fallback
        return "us"
    }
    
    // Helper function to map timezone to country code
    private static func countryCodeFromTimeZone(_ timeZoneIdentifier: String) -> String? {
        // Extract potential country from timezone identifier
        // Format is usually Region/City like "America/New_York" or "Asia/Tokyo"
        
        let commonTimeZoneMappings: [String: String] = [
            // Americas
            "America/New_York": "US",
            "America/Chicago": "US",
            "America/Los_Angeles": "US",
            "America/Toronto": "CA",
            "America/Mexico_City": "MX",
            "America/Sao_Paulo": "BR",
            "America/Buenos_Aires": "AR",
            
            // Europe
            "Europe/London": "GB",
            "Europe/Paris": "FR",
            "Europe/Berlin": "DE",
            "Europe/Rome": "IT",
            "Europe/Madrid": "ES",
            "Europe/Amsterdam": "NL",
            "Europe/Moscow": "RU",
            
            // Asia
            "Asia/Tokyo": "JP",
            "Asia/Shanghai": "CN",
            "Asia/Hong_Kong": "HK",
            "Asia/Singapore": "SG",
            "Asia/Seoul": "KR",
            "Asia/Kolkata": "IN",
            "Asia/Dubai": "AE",
            "Asia/Bangkok": "TH",
            
            // Oceania
            "Australia/Sydney": "AU",
            "Pacific/Auckland": "NZ",
            
            // Africa
            "Africa/Johannesburg": "ZA",
            "Africa/Cairo": "EG",
            "Africa/Lagos": "NG"
        ]
        
        // Check for exact match
        if let country = commonTimeZoneMappings[timeZoneIdentifier] {
            return country
        }
        
        // Try to match by city name (last component)
        let components = timeZoneIdentifier.split(separator: "/")
        if let city = components.last {
            for (timezone, country) in commonTimeZoneMappings {
                if timezone.hasSuffix(String(city)) {
                    return country
                }
            }
        }
        
        return nil
    }
    
    @objc private func localeDidChange() {
        refreshSystemPreferences()
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: StorageKeys.userDefaults)
        } catch {
            print("Failed to save user data: \(error)")
        }
    }
    
    private func loadPersistedData() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: StorageKeys.userDefaults),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            self.language = decoded.language
            self.country = decoded.country
            self.customLanguage = decoded.customLanguage
            self.customCountry = decoded.customCountry
            self.lastUpdated = decoded.lastUpdated
        }
        
        // Load userId from Keychain (more secure)
        self.userId = loadFromKeychain()
    }
    
    // MARK: - Keychain Methods (for secure userId storage)
    
    private func saveToKeychain(userId: String?) {
        guard let userId = userId else {
            deleteFromKeychain()
            return
        }
        
        let data = userId.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: StorageKeys.keychainUserId,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: StorageKeys.keychainUserId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let userId = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return userId
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: StorageKeys.keychainUserId
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Codable
extension User {
    enum CodingKeys: String, CodingKey {
        case language
        case country
        case customLanguage
        case customCountry
        case lastUpdated
        // userId is not included as it's stored in Keychain
    }
}
