//
//  AppSettings.swift
//  HealthKitTest
//
//  Created by David Wright on 2/19/21.
//

import Foundation

class AppSettings {
    static let shared = AppSettings()
    private init() {}
    
    // MARK: - Public Properties
    
    var healthIntegrationStatus: Bool {
        get {
            value(for: healthIntegrationStatusKey) ?? false // defaults to `false`
        }
        set {
            guard newValue != healthIntegrationStatus else { return }
            updateDefaults(for: healthIntegrationStatusKey, value: newValue)
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let healthIntegrationStatusKey = "healthIntegrationStatusKey"
}


// MARK: - Private Methods

extension AppSettings {
    
    private func updateDefaults(for key: String, value: Any) {
        userDefaults.set(value, forKey: key)
    }
    
    private func value<T>(for key: String) -> T? {
        userDefaults.value(forKey: key) as? T
    }
}
