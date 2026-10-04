// WaypointLab/Views/FavoritesView.swift
// Waypoint Lab - Saved Locations & Favorites Management View

import SwiftUI
import CoreLocation

public struct FavoritesView: View {
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @Binding public var selectedWaypoint: Waypoint?
    @Binding public var selectedTab: Int

    @State private var editingWaypoint: Waypoint?
    @State private var editedName: String = ""
    @State private var showingEditSheet: Bool = false

    public init(selectedWaypoint: Binding<Waypoint?>, selectedTab: Binding<Int>) {
        self._selectedWaypoint = selectedWaypoint
        self._selectedTab = selectedTab
    }

    public var body: some View {
        NavigationStack {
            List {
                if favoritesManager.favorites.isEmpty {
                    ContentUnavailableView(
                        "No Saved Favorites",
                        systemImage: "star.slash",
                        description: Text("Save coordinates from the map, search, or manual input to easily revisit them.")
                    )
                } else {
                    ForEach(favoritesManager.favorites) { item in
                        Button {
                            selectedWaypoint = item
                            selectedTab = 0 // Switch to Map tab
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    if let address = item.addressDescription {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Text(item.formattedCoordinates)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                favoritesManager.removeFavorite(withId: item.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                editingWaypoint = item
                                editedName = item.name
                                showingEditSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: favoritesManager.delete)
                }
            }
            .navigationTitle("Saved Favorites")
            .toolbar {
                if !favoritesManager.favorites.isEmpty {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                NavigationStack {
                    Form {
                        Section("Edit Favorite Name") {
                            TextField("Name", text: $editedName)
                        }
                    }
                    .navigationTitle("Edit Favorite")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingEditSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if var current = editingWaypoint, !editedName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    current.name = editedName
                                    favoritesManager.updateFavorite(current)
                                }
                                showingEditSheet = false
                            }
                        }
                    }
                }
            }
        }
    }
}
