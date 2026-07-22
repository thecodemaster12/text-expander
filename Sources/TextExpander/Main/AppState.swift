import Foundation
import Combine
import SwiftUI

/// Main application state coordinator managing UI state, engine synchronization, and persistence.
@MainActor
public final class AppState: ObservableObject {
    @Published public var snippets: [Snippet] = []
    @Published public var selectedSnippetID: UUID?
    @Published public var searchText: String = ""
    @Published public var selectedTagFilter: String? = nil
    @Published public var isGloballyEnabled: Bool = true {
        didSet {
            Task {
                await snippetEngine.setGloballyEnabled(isGloballyEnabled)
            }
        }
    }
    @Published public var isAccessibilityTrusted: Bool = false
    @Published public var lastExpansionNotice: String? = nil

    public let snippetEngine: SnippetEngine
    public let storageEngine: StorageEngine
    public let backupEngine: BackupEngine
    public let eventTapManager: EventTapManager

    public init(
        storageEngine: StorageEngine = StorageEngine(),
        backupEngine: BackupEngine = BackupEngine()
    ) {
        let engine = SnippetEngine()
        self.snippetEngine = engine
        self.storageEngine = storageEngine
        self.backupEngine = backupEngine
        self.eventTapManager = EventTapManager(snippetEngine: engine)

        self.eventTapManager.onExpansionTriggered = { [weak self] snippet, _ in
            Task { @MainActor in
                self?.lastExpansionNotice = "Expanded '\(snippet.trigger)'"
                self?.refreshSnippetsFromEngine()
            }
        }

        checkAccessibilityPermission()
        loadSnippets()
    }

    /// Checks system accessibility permissions and updates status.
    public func checkAccessibilityPermission() {
        let trusted = AccessibilityPermission.shared.isTrusted
        self.isAccessibilityTrusted = trusted
        if trusted {
            eventTapManager.start()
        }
    }

    /// Loads snippets from persistent storage into memory engine.
    public func loadSnippets() {
        Task {
            do {
                let loaded = try await storageEngine.loadSnippets()
                await snippetEngine.loadSnippets(loaded)
                let all = await snippetEngine.getAllSnippets()
                self.snippets = all
                if self.selectedSnippetID == nil, let first = all.first {
                    self.selectedSnippetID = first.id
                }
            } catch {
                print("[TextExpander] Error loading snippets: \(error)")
            }
        }
    }

    /// Refreshes UI state from in-memory engine.
    public func refreshSnippetsFromEngine() {
        Task {
            let updated = await snippetEngine.getAllSnippets()
            self.snippets = updated
        }
    }

    /// Upserts a snippet and saves to storage.
    public func saveSnippet(_ snippet: Snippet) {
        Task {
            let updated = await snippetEngine.upsertSnippet(snippet)
            self.snippets = updated
            try? await storageEngine.saveSnippets(updated)
        }
    }

    /// Creates a new snippet with default values.
    public func createNewSnippet() -> Snippet {
        let newSnippet = Snippet(
            trigger: ";newtrigger\(snippets.count + 1)",
            replacement: "Sample expansion text",
            label: "New Snippet"
        )
        saveSnippet(newSnippet)
        self.selectedSnippetID = newSnippet.id
        return newSnippet
    }

    /// Deletes selected or specified snippet.
    public func deleteSnippet(id: UUID) {
        Task {
            let updated = await snippetEngine.deleteSnippet(id: id)
            self.snippets = updated
            try? await storageEngine.saveSnippets(updated)
            if selectedSnippetID == id {
                selectedSnippetID = updated.first?.id
            }
        }
    }

    /// Toggles snippet enabled state.
    public func toggleSnippetEnabled(id: UUID) {
        Task {
            let updated = await snippetEngine.toggleSnippetEnabled(id: id)
            self.snippets = updated
            try? await storageEngine.saveSnippets(updated)
        }
    }

    /// Filtered list of snippets based on search term and selected tag.
    public var filteredSnippets: [Snippet] {
        snippets.filter { snippet in
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = snippet.trigger.lowercased().contains(query) ||
                                snippet.replacement.lowercased().contains(query) ||
                                snippet.label.lowercased().contains(query)
            }

            let matchesTag: Bool
            if let tag = selectedTagFilter, !tag.isEmpty {
                matchesTag = snippet.tags.contains(tag)
            } else {
                matchesTag = true
            }

            return matchesSearch && matchesTag
        }
    }

    /// Unique list of all tags present in snippets.
    public var availableTags: [String] {
        Array(Set(snippets.flatMap { $0.tags })).sorted()
    }

    /// Export snippets to JSON Data.
    public func exportJSONData() throws -> Data {
        try backupEngine.exportSnippetsData(snippets)
    }

    /// Import snippets from JSON Data.
    public func importJSONData(_ data: Data) throws {
        let imported = try backupEngine.importSnippetsData(data)
        Task {
            await snippetEngine.loadSnippets(imported)
            let all = await snippetEngine.getAllSnippets()
            self.snippets = all
            try await storageEngine.saveSnippets(all)
        }
    }

    /// Create manual backup.
    public func createBackup() throws -> URL {
        try backupEngine.createBackup(snippets: snippets)
    }
}
