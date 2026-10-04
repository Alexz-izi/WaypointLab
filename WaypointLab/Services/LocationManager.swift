// WaypointLab/Services/LocationManager.swift
// Waypoint Lab - CoreLocation Manager & Authorization Handler

import Foundation
import CoreLocation
import Combine

@MainActor
public final class LocationManager: NSObject, ObservableObject {
    @Published public private(set) var userLocation: CLLocationCoordinate2D?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var errorMessage: String?

    private let clManager: CLLocationManager

    public override init() {
        self.clManager = CLLocationManager()
        super.init()
        self.clManager.delegate = self
        self.clManager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = clManager.authorizationStatus
    }

    /// Requests standard when-in-use authorization from the user
    public func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            clManager.requestWhenInUseAuthorization()
        }
    }

    /// Starts active location updates
    public func startUpdating() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        clManager.startUpdatingLocation()
    }

    /// Stops receiving continuous updates to preserve battery
    public func stopUpdating() {
        clManager.stopUpdatingLocation()
    }

    /// Returns whether the user has authorized location access
    public var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            } else if status == .denied || status == .restricted {
                self.userLocation = nil
                self.errorMessage = "Location permission is denied. All map features and simulations remain functional."
            }
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor in
            self.userLocation = coordinate
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
        }
    }
}
