// WaypointLab/Views/SearchView.swift
// Waypoint Lab - MapKit Place Search View

import SwiftUI
import MapKit

public struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = SearchService()

    public var onSelect: (MKMapItem) -> Void

    public init(onSelect: @escaping (MKMapItem) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search cities, addresses, landmarks...", text: $searchService.searchQuery)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: searchService.searchQuery) { _, newValue in
                            searchService.updateQuery(newValue)
                        }
                        .onSubmit {
                            searchService.search(query: searchService.searchQuery)
                        }

                    if !searchService.searchQuery.isEmpty {
                        Button {
                            searchService.clear()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if searchService.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Error Message Bar
                if let error = searchService.searchError {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }

                // Content Lists
                List {
                    // Full Search Results
                    if !searchService.searchResults.isEmpty {
                        Section("Search Results") {
                            ForEach(searchService.searchResults, id: \.self) { item in
                                Button {
                                    onSelect(item)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name ?? "Unknown Location")
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        if let title = item.placemark.title {
                                            Text(title)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(String(format: "%.5f, %.5f", item.placemark.coordinate.latitude, item.placemark.coordinate.longitude))
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }

                    // Autocomplete Suggestions
                    if !searchService.suggestions.isEmpty {
                        Section("Suggestions") {
                            ForEach(searchService.suggestions) { suggestion in
                                Button {
                                    searchService.search(suggestion: suggestion)
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundStyle(.secondary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.title)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            if !suggestion.subtitle.isEmpty {
                                                Text(suggestion.subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    // Empty State
                    if searchService.searchResults.isEmpty && searchService.suggestions.isEmpty && !searchService.searchQuery.isEmpty && !searchService.isSearching {
                        ContentUnavailableView(
                            "No Results Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try searching for a different city, address, or landmark.")
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Search Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
