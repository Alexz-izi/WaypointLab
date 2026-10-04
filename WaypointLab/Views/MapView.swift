// WaypointLab/Views/MapView.swift
// Waypoint Lab - Modern SwiftUI Declarative Interactive Map View

import SwiftUI
import MapKit
import UniformTypeIdentifiers

public struct MapView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var routeManager: RouteSimulationManager
    @EnvironmentObject private var favoritesManager: FavoritesManager

    @Binding public var selectedWaypoint: Waypoint?
    @Binding public var mapStyleChoice: Int // 0: Standard, 1: Hybrid, 2: Imagery

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingManualInput: Bool = false
    @State private var showingSearchSheet: Bool = false
    @State private var showingSaveFavoriteAlert: Bool = false
    @State private var favoriteNameInput: String = ""
    @State private var copiedNotice: Bool = false

    public init(selectedWaypoint: Binding<Waypoint?>, mapStyleChoice: Binding<Int>) {
        self._selectedWaypoint = selectedWaypoint
        self._mapStyleChoice = mapStyleChoice
    }

    private var currentMapStyle: MapStyle {
        switch mapStyleChoice {
        case 1: return .hybrid(elevation: .realistic)
        case 2: return .imagery(elevation: .realistic)
        default: return .standard(elevation: .realistic)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Interactive Map Container with Coordinate Tap Detection
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        // User location annotation if authorized
                        if locationManager.isAuthorized {
                            UserAnnotation()
                        }

                        // Selected waypoint marker
                        if let waypoint = selectedWaypoint {
                            Marker(waypoint.name, coordinate: waypoint.coordinate)
                                .tint(.indigo)
                        }

                        // Route track polyline during simulation
                        if !routeManager.routePoints.isEmpty {
                            MapPolyline(coordinates: routeManager.routePoints.map { $0.coordinate })
                                .stroke(.blue.opacity(0.8), lineWidth: 4)
                        }

                        // Active route simulated location marker
                        if let simCoord = routeManager.currentCoordinate {
                            Annotation("Simulated Vehicle", coordinate: simCoord) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(radius: 4)
                            }
                        }

                        // In-app static preview coordinate marker
                        if let previewCoord = routeManager.previewCoordinate {
                            Marker("Preview Target", coordinate: previewCoord)
                                .tint(.green)
                        }
                    }
                    .mapStyle(currentMapStyle)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                        MapPitchToggle()
                    }
                    .onTapGesture { screenPoint in
                        if let coordinate = proxy.convert(screenPoint, from: .local) {
                            handleMapTap(coordinate: coordinate)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)

                // Overlay Controls & Selected Coordinate Details Card
                VStack(spacing: 12) {
                    // Top floating bar for Quick Actions
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Button {
                                centerOnUserLocation()
                            } label: {
                                Image(systemName: "location.fill")
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 3)
                            }

                            Button {
                                showingSearchSheet = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 3)
                            }

                            Button {
                                showingManualInput = true
                            } label: {
                                Image(systemName: "pencil.and.outline")
                                    .padding(12)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(.trailing, 16)
                    }

                    Spacer()

                    // Bottom Waypoint Information Card
                    if let waypoint = selectedWaypoint {
                        waypointInfoCard(waypoint: waypoint)
                    }
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Waypoint Lab")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingManualInput) {
                ManualCoordinateView(selectedWaypoint: $selectedWaypoint, onApply: { coord, name in
                    updateSelectedLocation(coordinate: coord, name: name)
                })
            }
            .sheet(isPresented: $showingSearchSheet) {
                SearchView(onSelect: { mapItem in
                    let coord = mapItem.placemark.coordinate
                    let name = mapItem.name ?? "Searched Place"
                    updateSelectedLocation(coordinate: coord, name: name, address: mapItem.placemark.title)
                })
            }
            .alert("Save Favorite Waypoint", isPresented: $showingSaveFavoriteAlert) {
                TextField("Favorite Name", text: $favoriteNameInput)
                Button("Save") {
                    if let waypoint = selectedWaypoint {
                        var updated = waypoint
                        if !favoriteNameInput.isEmpty {
                            updated.name = favoriteNameInput
                        }
                        favoritesManager.addFavorite(updated)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Waypoint Card View

    private func waypointInfoCard(waypoint: Waypoint) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(waypoint.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(waypoint.formattedCoordinates)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Button {
                    UIPasteboard.general.string = waypoint.formattedCoordinates
                    copiedNotice = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        copiedNotice = false
                    }
                } label: {
                    Image(systemName: copiedNotice ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(copiedNotice ? .green : .blue)
                }

                Button {
                    favoriteNameInput = waypoint.name
                    showingSaveFavoriteAlert = true
                } label: {
                    Image(systemName: "star")
                        .foregroundStyle(.yellow)
                }
            }

            if let address = waypoint.addressDescription {
                Text(address)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Divider()

            HStack(spacing: 12) {
                // In-App Preview Toggle Button
                Button {
                    if routeManager.isPreviewingLocation {
                        routeManager.stopLocationPreview()
                    } else {
                        routeManager.startLocationPreview(coordinate: waypoint.coordinate, label: waypoint.name)
                    }
                } label: {
                    Label(
                        routeManager.isPreviewingLocation ? "Stop Preview" : "Preview Location",
                        systemImage: routeManager.isPreviewingLocation ? "stop.fill" : "play.fill"
                    )
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(routeManager.isPreviewingLocation ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                    .foregroundStyle(routeManager.isPreviewingLocation ? .red : .blue)
                    .cornerRadius(8)
                }

                // Clear Selection Button
                Button {
                    selectedWaypoint = nil
                    if routeManager.isPreviewingLocation {
                        routeManager.stopLocationPreview()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 6)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        let newWaypoint = Waypoint(
            name: "Selected Point",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        self.selectedWaypoint = newWaypoint
    }

    private func updateSelectedLocation(coordinate: CLLocationCoordinate2D, name: String, address: String? = nil) {
        let newWaypoint = Waypoint(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            addressDescription: address
        )
        self.selectedWaypoint = newWaypoint
        withAnimation {
            cameraPosition = .camera(MapCamera(centerCoordinate: coordinate, distance: 3000))
        }
    }

    private func centerOnUserLocation() {
        locationManager.startUpdating()
        if let userCoord = locationManager.userLocation {
            withAnimation {
                cameraPosition = .camera(MapCamera(centerCoordinate: userCoord, distance: 2000))
            }
        } else {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }
}
