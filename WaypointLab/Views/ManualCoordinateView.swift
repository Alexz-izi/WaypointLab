// WaypointLab/Views/ManualCoordinateView.swift
// Waypoint Lab - Coordinate Input & Validation Interface

import SwiftUI
import CoreLocation

public struct ManualCoordinateView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding public var selectedWaypoint: Waypoint?
    public var onApply: (CLLocationCoordinate2D, String) -> Void

    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var labelText: String = "Manual Coordinate"
    @State private var validationError: String?
    @State private var copiedNotice: Bool = false

    public init(
        selectedWaypoint: Binding<Waypoint?>,
        onApply: @escaping (CLLocationCoordinate2D, String) -> Void
    ) {
        self._selectedWaypoint = selectedWaypoint
        self.onApply = onApply
    }

    private struct PresetLocation: Identifiable {
        let id = UUID()
        let name: String
        let lat: Double
        let lon: Double
    }

    private let presets: [PresetLocation] = [
        PresetLocation(name: "Apple Park", lat: 37.334900, lon: -122.009020),
        PresetLocation(name: "London Greenwich (0,0)", lat: 51.476900, lon: -0.000500),
        PresetLocation(name: "Tokyo Tower", lat: 35.658580, lon: 139.745433),
        PresetLocation(name: "Sydney Opera House", lat: -33.856800, lon: 151.215300),
        PresetLocation(name: "Equator / Prime Meridian (Null Island)", lat: 0.0, lon: 0.0)
    ]

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Target Coordinates")) {
                    TextField("Location Label", text: $labelText)

                    HStack {
                        Text("Latitude")
                            .frame(width: 90, alignment: .leading)
                            .foregroundStyle(.secondary)
                        TextField("-90.0 to 90.0", text: $latitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                    }

                    HStack {
                        Text("Longitude")
                            .frame(width: 90, alignment: .leading)
                            .foregroundStyle(.secondary)
                        TextField("-180.0 to 180.0", text: $longitudeText)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                    }

                    if let error = validationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section {
                    Button {
                        applyCoordinates()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Apply to Map")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(!canApply)

                    Button {
                        copyFormattedCoordinates()
                    } label: {
                        HStack {
                            Spacer()
                            Label(copiedNotice ? "Copied!" : "Copy Formatted Coordinates", systemImage: copiedNotice ? "checkmark" : "doc.on.doc")
                            Spacer()
                        }
                    }
                    .disabled(latitudeText.isEmpty || longitudeText.isEmpty)
                }

                Section(header: Text("Preset Waypoints")) {
                    ForEach(presets) { preset in
                        Button {
                            latitudeText = String(format: "%.6f", preset.lat)
                            longitudeText = String(format: "%.6f", preset.lon)
                            labelText = preset.name
                            validationError = nil
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(preset.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text("\(String(format: "%.4f", preset.lat)), \(String(format: "%.4f", preset.lon))")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manual Coordinates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let current = selectedWaypoint {
                    latitudeText = String(format: "%.6f", current.latitude)
                    longitudeText = String(format: "%.6f", current.longitude)
                    labelText = current.name
                }
            }
        }
    }

    private var canApply: Bool {
        guard let lat = Double(latitudeText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(longitudeText.trimmingCharacters(in: .whitespaces)) else {
            return false
        }
        return Waypoint.isValid(latitude: lat, longitude: lon)
    }

    private func applyCoordinates() {
        let latStr = latitudeText.trimmingCharacters(in: .whitespaces)
        let lonStr = longitudeText.trimmingCharacters(in: .whitespaces)

        guard let lat = Double(latStr) else {
            validationError = "Latitude must be a valid decimal number."
            return
        }

        guard let lon = Double(lonStr) else {
            validationError = "Longitude must be a valid decimal number."
            return
        }

        guard lat >= -90.0 && lat <= 90.0 else {
            validationError = "Latitude out of bounds. Must be between -90° and +90°."
            return
        }

        guard lon >= -180.0 && lon <= 180.0 else {
            validationError = "Longitude out of bounds. Must be between -180° and +180°."
            return
        }

        validationError = nil
        let name = labelText.trimmingCharacters(in: .whitespaces).isEmpty ? "Manual Location" : labelText
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        onApply(coordinate, name)
        dismiss()
    }

    private func copyFormattedCoordinates() {
        guard let lat = Double(latitudeText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(longitudeText.trimmingCharacters(in: .whitespaces)) else {
            return
        }
        let formatted = String(format: "%.6f, %.6f", lat, lon)
        UIPasteboard.general.string = formatted
        copiedNotice = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            copiedNotice = false
        }
    }
}
