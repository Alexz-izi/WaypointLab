// WaypointLab/Services/RouteSimulationManager.swift
// Waypoint Lab - GPX Parser & In-App Route Playback Simulation Engine

import Foundation
import CoreLocation
import Combine

public enum PlaybackState: String, CaseIterable {
    case idle = "Idle"
    case playing = "Playing"
    case paused = "Paused"
    case completed = "Completed"
}

@MainActor
public final class RouteSimulationManager: NSObject, ObservableObject {
    @Published public private(set) var routePoints: [RoutePoint] = []
    @Published public private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var state: PlaybackState = .idle
    @Published public var speedMultiplier: Double = 1.0 // 1x, 2x, 5x, 10x
    @Published public var routeName: String = "No Route Loaded"
    @Published public var statusMessage: String = "Ready"

    // Single-location preview mode
    @Published public private(set) var isPreviewingLocation: Bool = false
    @Published public private(set) var previewCoordinate: CLLocationCoordinate2D?

    private var playbackTask: Task<Void, Never>?

    public override init() {
        super.init()
    }

    // MARK: - In-App Single Location Preview

    /// Starts previewing a single location inside the app without altering system GPS
    public func startLocationPreview(coordinate: CLLocationCoordinate2D, label: String = "Selected Point") {
        stopPlayback()
        guard Waypoint.isValid(latitude: coordinate.latitude, longitude: coordinate.longitude) else {
            statusMessage = "Invalid coordinates for preview."
            return
        }
        self.previewCoordinate = coordinate
        self.isPreviewingLocation = true
        self.statusMessage = "Previewing \(label) [In-App Only]"
    }

    /// Stops the in-app single location preview
    public func stopLocationPreview() {
        self.isPreviewingLocation = false
        self.previewCoordinate = nil
        self.statusMessage = "Preview stopped."
    }

    // MARK: - GPX Loading & Parsing

    /// Loads route from raw GPX XML string
    public func loadGPX(content: String, name: String = "Imported Route") {
        stopPlayback()
        let parsed = GPXParser.parse(xmlString: content)
        guard !parsed.isEmpty else {
            statusMessage = "Failed to parse GPX content or route is empty."
            return
        }
        self.routePoints = parsed
        self.routeName = name
        self.currentIndex = 0
        self.currentCoordinate = parsed.first?.coordinate
        self.state = .idle
        self.statusMessage = "Loaded \(parsed.count) points from \(name)."
    }

    /// Loads route from a local file URL
    public func loadGPX(from fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            if let string = String(data: data, encoding: .utf8) {
                let filename = fileURL.deletingPathExtension().lastPathComponent
                loadGPX(content: string, name: filename)
            } else {
                statusMessage = "Unable to read GPX file encoding."
            }
        } catch {
            statusMessage = "Error loading GPX: \(error.localizedDescription)"
        }
    }

    // MARK: - Playback Controls

    public func play() {
        guard !routePoints.isEmpty else {
            statusMessage = "No route points loaded."
            return
        }

        if state == .completed {
            currentIndex = 0
        }

        state = .playing
        statusMessage = "Simulation playing at \(Int(speedMultiplier))x"
        startPlaybackLoop()
    }

    public func pause() {
        guard state == .playing else { return }
        playbackTask?.cancel()
        playbackTask = nil
        state = .paused
        statusMessage = "Simulation paused at point \(currentIndex + 1) of \(routePoints.count)"
    }

    public func resume() {
        guard state == .paused else { return }
        play()
    }

    public func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        state = .idle
        currentIndex = 0
        if let first = routePoints.first {
            currentCoordinate = first.coordinate
        } else {
            currentCoordinate = nil
        }
        statusMessage = "Simulation stopped."
    }

    public func seek(to index: Int) {
        guard !routePoints.isEmpty else { return }
        let clamped = max(0, min(index, routePoints.count - 1))
        currentIndex = clamped
        currentCoordinate = routePoints[clamped].coordinate
    }

    public var progress: Double {
        guard routePoints.count > 1 else { return 0.0 }
        return Double(currentIndex) / Double(routePoints.count - 1)
    }

    private func startPlaybackLoop() {
        playbackTask?.cancel()
        playbackTask = Task {
            while !Task.isCancelled && currentIndex < routePoints.count {
                self.currentCoordinate = routePoints[currentIndex].coordinate
                self.currentIndex += 1

                if self.currentIndex >= self.routePoints.count {
                    self.state = .completed
                    self.statusMessage = "Route playback complete."
                    break
                }

                // Compute base step interval divided by speed multiplier (base: 1.0 second per waypoint)
                let baseInterval: Double = 1.0
                let stepDelay = max(0.1, baseInterval / max(0.25, self.speedMultiplier))
                let nanoSeconds = UInt64(stepDelay * 1_000_000_000)

                try? await Task.sleep(nanoseconds: nanoSeconds)
            }
        }
    }
}

// MARK: - Dedicated GPX XML Parser

public final class GPXParser: NSObject, XMLParserDelegate {
    private var points: [RoutePoint] = []
    private var currentElement: String = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentTimestamp: Date?
    private var textBuffer: String = ""

    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public static func parse(xmlString: String) -> [RoutePoint] {
        guard let data = xmlString.data(using: .utf8) else { return [] }
        let parser = GPXParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        if xmlParser.parse() {
            return parser.points
        }
        return []
    }

    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        currentElement = elementName
        textBuffer = ""

        if elementName == "trkpt" || elementName == "wpt" {
            if let latString = attributeDict["lat"], let lat = Double(latString),
               let lonString = attributeDict["lon"], let lon = Double(lonString) {
                currentLat = lat
                currentLon = lon
            }
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    public func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        if elementName == "ele", let eleVal = Double(trimmed) {
            currentEle = eleVal
        } else if elementName == "time" {
            currentTimestamp = isoDateFormatter.date(from: trimmed) ?? ISO8601DateFormatter().date(from: trimmed)
        } else if elementName == "trkpt" || elementName == "wpt" {
            if let lat = currentLat, let lon = currentLon, Waypoint.isValid(latitude: lat, longitude: lon) {
                let point = RoutePoint(
                    sequenceIndex: points.count,
                    latitude: lat,
                    longitude: lon,
                    elevation: currentEle,
                    timestamp: currentTimestamp
                )
                points.append(point)
            }
            currentLat = nil
            currentLon = nil
            currentEle = nil
            currentTimestamp = nil
        }
    }
}
