import Foundation

/// High-performance actor managing in-memory O(1) hash map snippet matching and expansion logic.
public actor SnippetEngine {
    private var allSnippets: [UUID: Snippet] = [:]
    /// Enabled snippets with case-sensitive triggers, keyed by exact trigger string.
    private var caseSensitiveTriggers: [String: Snippet] = [:]
    /// Enabled snippets with case-insensitive triggers, keyed by lowercased trigger string.
    private var caseInsensitiveTriggers: [String: Snippet] = [:]
    /// Longest trigger length across both maps, bounding the per-keystroke suffix search.
    private var maxTriggerLength: Int = 0
    private let variableResolver: VariableResolver
    public var isGloballyEnabled: Bool = true

    public init(variableResolver: VariableResolver = VariableResolver()) {
        self.variableResolver = variableResolver
    }

    /// Replaces the entire snippet registry in O(N) setup and builds O(1) hash map tables.
    public func loadSnippets(_ snippets: [Snippet]) {
        allSnippets.removeAll(keepingCapacity: true)
        caseSensitiveTriggers.removeAll(keepingCapacity: true)
        caseInsensitiveTriggers.removeAll(keepingCapacity: true)
        maxTriggerLength = 0

        for snippet in snippets {
            allSnippets[snippet.id] = snippet
            indexSnippet(snippet)
        }
    }

    /// Adds a snippet's trigger to the lookup maps if enabled, and extends maxTriggerLength.
    private func indexSnippet(_ snippet: Snippet) {
        guard snippet.isEnabled else { return }
        if snippet.isCaseSensitive {
            caseSensitiveTriggers[snippet.trigger] = snippet
        } else {
            caseInsensitiveTriggers[snippet.trigger.lowercased()] = snippet
        }
        maxTriggerLength = max(maxTriggerLength, snippet.trigger.count)
    }

    /// Removes a snippet's trigger from whichever lookup map it may occupy.
    private func unindexSnippet(_ snippet: Snippet) {
        if snippet.isCaseSensitive {
            caseSensitiveTriggers.removeValue(forKey: snippet.trigger)
        } else {
            caseInsensitiveTriggers.removeValue(forKey: snippet.trigger.lowercased())
        }
    }

    /// Recomputes maxTriggerLength from the current maps (only needed after a removal/rename,
    /// since indexSnippet alone can only grow it). Cheap: only runs on snippet mutation, never
    /// on the keystroke-evaluation hot path.
    private func recomputeMaxTriggerLength() {
        let longestCaseSensitive = caseSensitiveTriggers.keys.map(\.count).max() ?? 0
        let longestCaseInsensitive = caseInsensitiveTriggers.keys.map(\.count).max() ?? 0
        maxTriggerLength = max(longestCaseSensitive, longestCaseInsensitive)
    }

    /// Retrieves all snippets stored in memory.
    public func getAllSnippets() -> [Snippet] {
        Array(allSnippets.values).sorted { $0.trigger.localizedStandardCompare($1.trigger) == .orderedAscending }
    }

    /// Upserts (adds or updates) a snippet in O(1) time.
    public func upsertSnippet(_ snippet: Snippet) -> [Snippet] {
        var updated = snippet
        updated.dateModified = Date()

        if let existing = allSnippets[snippet.id] {
            unindexSnippet(existing)
        }

        allSnippets[snippet.id] = updated
        indexSnippet(updated)
        recomputeMaxTriggerLength()

        return getAllSnippets()
    }

    /// Deletes a snippet by ID in O(1) time.
    public func deleteSnippet(id: UUID) -> [Snippet] {
        if let existing = allSnippets.removeValue(forKey: id) {
            unindexSnippet(existing)
            recomputeMaxTriggerLength()
        }
        return getAllSnippets()
    }

    /// Toggles active state of a snippet.
    public func toggleSnippetEnabled(id: UUID) -> [Snippet] {
        guard var snippet = allSnippets[id] else { return getAllSnippets() }
        snippet.isEnabled.toggle()
        return upsertSnippet(snippet)
    }

    /// Evaluates word buffer for snippet expansion in O(maxTriggerLength) time, independent
    /// of how many snippets are registered.
    public func evaluateBuffer(_ buffer: WordBuffer) -> (snippet: Snippet, expansionResult: VariableResolutionResult)? {
        guard isGloballyEnabled else { return nil }

        guard let (snippet, _) = buffer.findMatchingTrigger(
            caseSensitiveTriggers: caseSensitiveTriggers,
            caseInsensitiveTriggers: caseInsensitiveTriggers,
            maxTriggerLength: maxTriggerLength
        ) else {
            return nil
        }

        let resolution = variableResolver.resolve(template: snippet.replacement)
        recordUsage(for: snippet.id)

        return (snippet, resolution)
    }

    private func recordUsage(for snippetID: UUID) {
        guard var snippet = allSnippets[snippetID] else { return }
        snippet.usageCount += 1
        allSnippets[snippetID] = snippet
        indexSnippet(snippet)
    }

    /// Sets global enabled/disabled state.
    public func setGloballyEnabled(_ enabled: Bool) {
        self.isGloballyEnabled = enabled
    }
}
