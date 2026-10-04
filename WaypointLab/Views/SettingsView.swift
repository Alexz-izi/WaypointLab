// WaypointLab/Views/SettingsView.swift
// Waypoint Lab - Application Configuration & Settings View

import SwiftUI
import CoreLocation

public struct SettingsView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var routeManager: RouteSimulationManager

    @Binding public var mapStyleChoice: Int // 0: Standard, 1: Hybrid, 2: Imagery

    public init(mapStyleChoice: Binding<Int>) {
        self._mapStyleChoice = mapStyleChoice
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Map Customization
                Section("Map Display") {
                    Picker("Appearance", selection: $mapStyleChoice) {
                        Text("Standard").tag(0)
                        Text("Satellite / Hybrid").tag(1)
                        Text("Satellite Only").tag(2)
                    }
                    .pickerStyle(.menu)
                }

                // Default Route Playback Speed
                Section("Route Simulation Defaults") {
                    HStack {
                        Text("Playback Rate")
                        Spacer()
                        Text("\(routeManager.speedMultiplier, specifier: "%.1f")x")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $routeManager.speedMultiplier, in: 0.5...10.0, step: 0.5) {
                        Text("Speed")
                    } minimumValueLabel: {
                        Text("0.5x").font(.caption2)
                    } maximumValueLabel: {
                        Text("10x").font(.caption2)
                    }
                }

                // Core Location Permissions Status
                Section("Location Services") {
                    HStack {
                        Text("System Permission")
                        Spacer()
                        Text(permissionStatusText)
                            .foregroundStyle(permissionStatusColor)
                    }

                    Text("Waypoint Lab requests When-in-Use location access solely to display your current position and center the map. All manual coordinates, place search, and route simulation features operate independently if permission is withheld.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Architecture & Platform Limitations
                Section("Developer Disclosure & Platform Architecture") {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("In-App Trajectory vs System GPS", systemImage: "shield.lefthalf.filled")
                            .font(.subheadline.bold())
                        Text("Apple's sandbox architecture isolates applications from modifying system-wide CoreLocation services. Simulated routes and coordinates within Waypoint Lab exist strictly inside this app's user interface and test engine.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("SideStore & 7-Day Free Accounts", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline.bold())
                        Text("When sideloaded via a free Apple Account, apps must be refreshed within 7 days. SideStore automates this via a local WireGuard loopback VPN on your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                // App Info
                Section("About Waypoint Lab") {
                    HStack {
                        Text("Application Name")
                        Spacer()
                        Text("Waypoint Lab")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Bundle Identifier")
                        Spacer()
                        Text("com.example.waypointlab")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Target Hardware")
                        Spacer()
                        Text("iPhone 14 Pro (iOS 26.5)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var permissionStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse: return "Authorized When In Use"
        case .authorizedAlways: return "Authorized Always"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private var permissionStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted: return .red
        default: return .orange
        }
    }
}
