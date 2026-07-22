import Foundation

/// High-performance actor managing in-memory O(1) hash map snippet matching and expansion logic.
public actor SnippetEngine {
    private var snippetsMap: [String: Snippet] = [:]
    private var allSnippets: [UUID: Snippet] = [:]
    private let variableResolver: VariableResolver
    public var isGloballyEnabled: Bool = true

    public init(variableResolver: VariableResolver = VariableResolver()) {
        self.variableResolver = variableResolver
    }

    /// Replaces the entire snippet registry in O(N) setup and builds O(1) hash map table.
    public func loadSnippets(_ snippets: [Snippet]) {
        allSnippets.removeAll(keepingCapacity: true)
        snippetsMap.removeAll(keepingCapacity: true)

        for snippet in snippets {
            allSnippets[snippet.id] = snippet
            if snippet.isEnabled {
                snippetsMap[snippet.lookupKey] = snippet
            }
        }
    }

    /// Retrieves all snippets stored in memory.
    public func getAllSnippets() -> [Snippet] {
        Array(allSnippets.values).sorted { $0.trigger.localizedStandardCompare($1.trigger) == .orderedAscending }
    }

    /// Upserts (adds or updates) a snippet in O(1) time.
    public func upsertSnippet(_ snippet: Snippet) -> [Snippet] {
        var updated = snippet
        updated.dateModified = Date()

        allSnippets[snippet.id] = updated

        // Remove old lookup key if trigger/sensitivity changed
        snippetsMap.values.filter { $0.id == snippet.id }.forEach { oldSnippet in
            snippetsMap.removeValue(forKey: oldSnippet.lookupKey)
        }

        if updated.isEnabled {
            snippetsMap[updated.lookupKey] = updated
        }

        return getAllSnippets()
    }

    /// Deletes a snippet by ID in O(1) time.
    public func deleteSnippet(id: UUID) -> [Snippet] {
        if let existing = allSnippets.removeValue(forKey: id) {
            snippetsMap.removeValue(forKey: existing.lookupKey)
        }
        return getAllSnippets()
    }

    /// Toggles active state of a snippet.
    public func toggleSnippetEnabled(id: UUID) -> [Snippet] {
        guard var snippet = allSnippets[id] else { return getAllSnippets() }
        snippet.isEnabled.toggle()
        return upsertSnippet(snippet)
    }

    /// Evaluates word buffer for snippet expansion in O(1) time.
    public func evaluateBuffer(_ buffer: WordBuffer) -> (snippet: Snippet, expansionResult: VariableResolutionResult)? {
        guard isGloballyEnabled else { return nil }

        guard let (snippet, _) = buffer.findMatchingTrigger(in: snippetsMap) else {
            return nil
        }

        let resolution = variableResolver.resolve(template: snippet.replacement)

        // Increment usage count
        Task {
            recordUsage(for: snippet.id)
        }

        return (snippet, resolution)
    }

    private func recordUsage(for snippetID: UUID) {
        guard var snippet = allSnippets[snippetID] else { return }
        snippet.usageCount += 1
        allSnippets[snippetID] = snippet
        if snippet.isEnabled {
            snippetsMap[snippet.lookupKey] = snippet
        }
    }

    /// Sets global enabled/disabled state.
    public func setGloballyEnabled(_ enabled: Bool) {
        self.isGloballyEnabled = enabled
    }
}
