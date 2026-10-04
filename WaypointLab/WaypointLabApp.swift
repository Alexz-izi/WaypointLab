// WaypointLab/WaypointLabApp.swift
// Waypoint Lab - Native iOS Application Entry Point

import SwiftUI

@main
struct WaypointLabApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var routeManager = RouteSimulationManager()
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(locationManager)
                .environmentObject(routeManager)
                .environmentObject(favoritesManager)
                .preferredColorScheme(nil) // Respect system light/dark mode
        }
    }
}
