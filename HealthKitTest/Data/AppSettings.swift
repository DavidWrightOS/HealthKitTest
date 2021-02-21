//
//  AppSettings.swift
//  HealthKitTest
//
//  Created by David Wright on 2/19/21.
//

import Foundation

@objc protocol SettingsTracking {
    @objc func healthIntegrationIsEnabledChanged()
}

extension SettingsTracking {
    func registerForhealthIntegrationIsEnabledChanges() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(healthIntegrationIsEnabledChanged),
                                               name: .healthIntegrationIsEnabledChanged,
                                               object: nil)
    }
}

class AppSettings {
    static let shared = AppSettings()
    private init() {}
    
    // MARK: - Public Properties
    
    var healthIntegrationIsEnabled: Bool {
        get {
            value(for: healthIntegrationIsEnabledKey) ?? false // defaults to `false`
        }
        set {
            guard newValue != healthIntegrationIsEnabled else { return }
            updateDefaults(for: healthIntegrationIsEnabledKey, value: newValue)
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let healthIntegrationIsEnabledKey = "healthIntegrationIsEnabledKey"
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


extension Notification.Name {
    static let healthIntegrationIsEnabledChanged = Notification.Name("healthIntegrationIsEnabledChanged")
}
