// WaypointLab/Views/MainTabView.swift
// Waypoint Lab - Main Tab Coordinator & Navigation Root

import SwiftUI
import CoreLocation

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var selectedWaypoint: Waypoint?
    @State private var mapStyleChoice: Int = 0 // 0: Standard, 1: Hybrid, 2: Imagery

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            MapView(selectedWaypoint: $selectedWaypoint, mapStyleChoice: $mapStyleChoice)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)

            RouteSimulationView()
                .tabItem {
                    Label("Simulation", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
                .tag(1)

            FavoritesView(selectedWaypoint: $selectedWaypoint, selectedTab: $selectedTab)
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
                .tag(2)

            SettingsView(mapStyleChoice: $mapStyleChoice)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
