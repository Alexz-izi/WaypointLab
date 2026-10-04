// WaypointLab/Models/RoutePoint.swift
// Waypoint Lab - Route Track & Waypoint Trajectory Model

import Foundation
import CoreLocation

/// Represents a single waypoint node along a GPX route track
public struct RoutePoint: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let sequenceIndex: Int
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double?
    public let timestamp: Date?

    public init(
        id: UUID = UUID(),
        sequenceIndex: Int,
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        timestamp: Date? = nil
    ) {
        self.id = id
        self.sequenceIndex = sequenceIndex
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timestamp = timestamp
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var isValid: Bool {
        Waypoint.isValid(latitude: latitude, longitude: longitude)
    }
}
