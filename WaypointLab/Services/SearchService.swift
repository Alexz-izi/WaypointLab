// WaypointLab/Services/SearchService.swift
// Waypoint Lab - MapKit Place Search & Autocompletion Service

import Foundation
import MapKit
import Combine

public struct SearchSuggestion: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

@MainActor
public final class SearchService: NSObject, ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public private(set) var suggestions: [SearchSuggestion] = []
    @Published public private(set) var searchResults: [MKMapItem] = []
    @Published public private(set) var isSearching: Bool = false
    @Published public var searchError: String?

    private var completer: MKLocalSearchCompleter
    private var activeSearchTask: Task<Void, Never>?

    public override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = [.address, .pointOfInterest]
    }

    /// Updates autocomplete query
    public func updateQuery(_ query: String) {
        self.searchQuery = query
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            self.suggestions = []
            return
        }
        completer.queryFragment = trimmed
    }

    /// Performs full place search using MKLocalSearch
    public func search(query: String, region: MKCoordinateRegion? = nil) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        activeSearchTask?.cancel()
        isSearching = true
        searchError = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let region = region {
            request.region = region
        }

        activeSearchTask = Task {
            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                guard !Task.isCancelled else { return }
                self.searchResults = response.mapItems
                self.isSearching = false
                if response.mapItems.isEmpty {
                    self.searchError = "No matching locations found."
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.isSearching = false
                self.searchError = error.localizedDescription
                self.searchResults = []
            }
        }
    }

    /// Selects an autocomplete suggestion and resolves it to a full map item
    public func search(suggestion: SearchSuggestion, region: MKCoordinateRegion? = nil) {
        let fullQuery = suggestion.subtitle.isEmpty ? suggestion.title : "\(suggestion.title), \(suggestion.subtitle)"
        search(query: fullQuery, region: region)
    }

    /// Clears active search state
    public func clear() {
        activeSearchTask?.cancel()
        searchQuery = ""
        suggestions = []
        searchResults = []
        isSearching = false
        searchError = nil
    }
}

extension SearchService: MKLocalSearchCompleterDelegate {
    public nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.map {
            SearchSuggestion(title: $0.title, subtitle: $0.subtitle)
        }
        Task { @MainActor in
            self.suggestions = results
        }
    }

    public nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.searchError = error.localizedDescription
        }
    }
}
