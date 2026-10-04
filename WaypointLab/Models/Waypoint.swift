// WaypointLab/Models/Waypoint.swift
// Waypoint Lab - Location & Point of Interest Model

import Foundation
import CoreLocation

/// Represents a point on the map selected manually, via search, or saved as a favorite.
public struct Waypoint: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    public var addressDescription: String?

    public init(
        id: UUID = UUID(),
        name: String = "Selected Point",
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        addressDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.addressDescription = addressDescription
    }

    /// Computed CLLocationCoordinate2D for MapKit compatibility
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Formatted coordinates string: e.g. "37.774900, -122.419400"
    public var formattedCoordinates: String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }

    /// Validates if coordinates conform to the standard WGS84 bounding limits
    public var isValidCoordinate: Bool {
        Waypoint.isValid(latitude: latitude, longitude: longitude)
    }

    /// Static validator for manual entry checking
    public static func isValid(latitude: Double, longitude: Double) -> Bool {
        guard !latitude.isNaN, !longitude.isNaN else { return false }
        return latitude >= -90.0 && latitude <= 90.0 && longitude >= -180.0 && longitude <= 180.0
    }
}
