//
//  WeatherService.swift
//  HydraTrack
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()

    @Published var currentTemperatureCelsius: Double?
    @Published var weatherAdjustmentMl: Int = 0
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool = false

    @AppStorage("weatherAdjustmentEnabled") private var weatherAdjustmentEnabled: Bool = false

    private var lastFetchTime: Date?
    private let fetchCooldown: TimeInterval = 30 * 60 // 30 minutes

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Save battery
        locationStatus = locationManager.authorizationStatus
        isEnabled = weatherAdjustmentEnabled
    }

    // MARK: - Public Methods

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func setEnabled(_ enabled: Bool) {
        weatherAdjustmentEnabled = enabled
        isEnabled = enabled

        if enabled {
            Task {
                await fetchWeatherIfNeeded()
            }
        } else {
            // Clear adjustment when disabled
            weatherAdjustmentMl = 0
            currentTemperatureCelsius = nil
        }
    }

    func fetchWeatherIfNeeded() async {
        // Check if feature is enabled
        guard isEnabled else {
            weatherAdjustmentMl = 0
            return
        }

        // Check cooldown to avoid excessive API calls
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < fetchCooldown {
            return
        }

        // Check if we have location permission
        guard locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways else {
            print("WeatherService: Location not authorized")
            return
        }

        // Get current location
        guard let location = locationManager.location else {
            locationManager.requestLocation()
            return
        }

        await fetchWeather(for: location)
    }

    // MARK: - Private Methods

    private func fetchWeather(for location: CLLocation) async {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        // Open-Meteo API (free, no API key required)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"

        guard let url = URL(string: urlString) else {
            print("WeatherService: Invalid URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let temp = response.current_weather.temperature

            currentTemperatureCelsius = temp
            weatherAdjustmentMl = calculateAdjustment(temperatureCelsius: temp)
            lastFetchTime = Date()

            print("WeatherService: Temperature \(Int(temp))°C, adjustment +\(weatherAdjustmentMl) mL")
        } catch {
            print("WeatherService error: \(error.localizedDescription)")
        }
    }

    private func calculateAdjustment(temperatureCelsius: Double) -> Int {
        guard isEnabled else { return 0 }

        switch temperatureCelsius {
        case ..<20:
            return 0
        case 20..<25:
            return 50
        case 25..<30:
            return 100
        case 30..<35:
            return 175
        default: // 35°C and above
            return 250
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await fetchWeather(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("WeatherService location error: \(error.localizedDescription)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            locationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
    }
}

// MARK: - Open-Meteo Response Models

struct OpenMeteoResponse: Codable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
}
