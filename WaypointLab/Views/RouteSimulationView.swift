// WaypointLab/Views/RouteSimulationView.swift
// Waypoint Lab - In-App Route Playback & GPX Import View

import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

public struct RouteSimulationView: View {
    @EnvironmentObject private var routeManager: RouteSimulationManager

    @State private var showingFileImporter: Bool = false
    @State private var importErrorMessage: String?

    private let speedOptions: [Double] = [0.5, 1.0, 2.0, 5.0, 10.0]

    public var body: some View {
        NavigationStack {
            List {
                // System Boundary Disclaimer Card
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("In-App Trajectory Simulation")
                                .font(.subheadline.bold())
                            Text("This feature animates waypoints and coordinates inside Waypoint Lab for path inspection. It does not alter your iPhone's system-wide GPS location or feed fake data to external applications.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Active Route Overview
                Section("Route Information") {
                    HStack {
                        Text("Route Name")
                        Spacer()
                        Text(routeManager.routeName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Waypoints")
                        Spacer()
                        Text("\(routeManager.routePoints.count) points")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Current Status")
                        Spacer()
                        Text(routeManager.state.rawValue)
                            .bold()
                            .foregroundStyle(statusColor)
                    }

                    if let current = routeManager.currentCoordinate {
                        HStack {
                            Text("Current Position")
                            Spacer()
                            Text(String(format: "%.5f, %.5f", current.latitude, current.longitude))
                                .font(.caption.monospaced())
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // Playback Controls
                Section("Playback Controls") {
                    // Progress Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(routeManager.progress * 100))%")
                                .font(.caption.monospaced())
                        }

                        ProgressView(value: routeManager.progress)
                    }
                    .padding(.vertical, 4)

                    // Control Buttons
                    HStack(spacing: 20) {
                        Spacer()

                        // Play / Pause / Resume Button
                        switch routeManager.state {
                        case .idle, .completed:
                            Button {
                                routeManager.play()
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.blue)
                            }
                            .disabled(routeManager.routePoints.isEmpty)

                        case .playing:
                            Button {
                                routeManager.pause()
                            } label: {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.orange)
                            }

                        case .paused:
                            Button {
                                routeManager.resume()
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.green)
                            }
                        }

                        // Stop Button
                        Button {
                            routeManager.stopPlayback()
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.red)
                        }
                        .disabled(routeManager.state == .idle)

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    // Speed Multiplier Picker
                    Picker("Speed Multiplier", selection: $routeManager.speedMultiplier) {
                        ForEach(speedOptions, id: \.self) { speed in
                            Text("\(speed, specifier: speed == 0.5 ? "%.1f" : "%.0f")x").tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // GPX Import & Sample Actions
                Section("GPX Route Sources") {
                    Button {
                        loadBundledSampleGPX()
                    } label: {
                        Label("Load Bundled Sample Route (Cupertino Loop)", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Import Custom GPX File", systemImage: "square.and.arrow.down")
                    }
                }

                // Route Waypoint Nodes
                if !routeManager.routePoints.isEmpty {
                    Section("Waypoint Sequence (\(routeManager.routePoints.count))") {
                        ForEach(routeManager.routePoints) { pt in
                            HStack {
                                Text("#\(pt.sequenceIndex + 1)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 38, alignment: .leading)

                                Text(String(format: "%.5f, %.5f", pt.latitude, pt.longitude))
                                    .font(.body.monospaced())

                                Spacer()

                                if pt.sequenceIndex == routeManager.currentIndex {
                                    Image(systemName: "arrow.left")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Route Simulation")
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.xml, UTType(filenameExtension: "gpx") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let selectedURL = urls.first {
                        let hasSecurityAccess = selectedURL.startAccessingSecurityScopedResource()
                        defer {
                            if hasSecurityAccess {
                                selectedURL.stopAccessingSecurityScopedResource()
                            }
                        }
                        routeManager.loadGPX(from: selectedURL)
                    }
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .alert("Import Error", isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "")
            }
        }
    }

    private var statusColor: Color {
        switch routeManager.state {
        case .idle: return .secondary
        case .playing: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }

    private func loadBundledSampleGPX() {
        if let path = Bundle.main.path(forResource: "SampleRoute", ofType: "gpx") {
            let url = URL(fileURLWithPath: path)
            routeManager.loadGPX(from: url)
        } else {
            // Fallback inline sample coordinates around Cupertino
            let sampleXML = """
            <?xml version="1.0" encoding="UTF-8"?>
            <gpx version="1.1" creator="WaypointLab">
              <trk>
                <name>Cupertino Sample Loop</name>
                <trkseg>
                  <trkpt lat="37.334900" lon="-122.009020"><ele>50</ele></trkpt>
                  <trkpt lat="37.333000" lon="-122.005000"><ele>51</ele></trkpt>
                  <trkpt lat="37.330000" lon="-122.007000"><ele>52</ele></trkpt>
                  <trkpt lat="37.331500" lon="-122.012000"><ele>50</ele></trkpt>
                  <trkpt lat="37.334900" lon="-122.009020"><ele>50</ele></trkpt>
                </trkseg>
              </trk>
            </gpx>
            """
            routeManager.loadGPX(content: sampleXML, name: "Cupertino Sample Track")
        }
    }
}
