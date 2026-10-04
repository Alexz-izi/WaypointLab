// WaypointLab/Services/FavoritesManager.swift
// Waypoint Lab - Persistent Favorites Storage Manager

import Foundation
import Combine

@MainActor
public final class FavoritesManager: ObservableObject {
    @Published public private(set) var favorites: [Waypoint] = []

    private let storageKey = "com.waypointlab.savedFavorites"

    public init() {
        loadFavorites()
    }

    /// Loads saved waypoints from persistent storage
    public func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            // Seed initial sample landmarks if empty
            seedInitialFavorites()
            return
        }

        do {
            let decoder = JSONDecoder()
            self.favorites = try decoder.decode([Waypoint].self, from: data)
        } catch {
            print("Failed to decode favorites: \(error)")
            seedInitialFavorites()
        }
    }

    /// Saves a new waypoint to favorites
    public func addFavorite(_ waypoint: Waypoint) {
        if !favorites.contains(where: { $0.id == waypoint.id }) {
            favorites.insert(waypoint, at: 0)
            persist()
        }
    }

    /// Updates an existing favorite's name or metadata
    public func updateFavorite(_ waypoint: Waypoint) {
        if let index = favorites.firstIndex(where: { $0.id == waypoint.id }) {
            favorites[index] = waypoint
            persist()
        }
    }

    /// Removes a favorite by ID
    public func removeFavorite(withId id: UUID) {
        favorites.removeAll { $0.id == id }
        persist()
    }

    /// Deletes favorites at specified index offsets (for SwiftUI List .onDelete)
    public func delete(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        persist()
    }

    /// Clears all stored favorites
    public func clearAll() {
        favorites.removeAll()
        persist()
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favorites)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode favorites: \(error)")
        }
    }

    private func seedInitialFavorites() {
        self.favorites = [
            Waypoint(
                name: "Apple Park, Cupertino",
                latitude: 37.334900,
                longitude: -122.009020,
                addressDescription: "1 Apple Park Way, Cupertino, CA"
            ),
            Waypoint(
                name: "San Francisco Ferry Building",
                latitude: 37.795500,
                longitude: -122.393700,
                addressDescription: "1 Ferry Building, San Francisco, CA"
            ),
            Waypoint(
                name: "Tokyo Tower",
                latitude: 35.658580,
                longitude: 139.745433,
                addressDescription: "4 Chome-2-8 Shibakoen, Minato City, Tokyo"
            )
        ]
        persist()
    }
}
