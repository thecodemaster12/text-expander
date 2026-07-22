import Foundation

/// Asynchronous thread-safe storage engine for atomic snippet persistence.
public actor StorageEngine {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = appSupport.appendingPathComponent("TextExpander", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            self.fileURL = folder.appendingPathComponent("snippets.json")
        }

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Loads snippets from disk, initializing default snippets if file does not exist.
    public func loadSnippets() throws -> [Snippet] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let defaultSnippets = Self.makeDefaultSnippets()
            try saveSnippets(defaultSnippets)
            return defaultSnippets
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([Snippet].self, from: data)
    }

    /// Saves snippets asynchronously and atomically to disk.
    public func saveSnippets(_ snippets: [Snippet]) throws {
        let data = try encoder.encode(snippets)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Factory method providing default initial snippets for new installations.
    public static func makeDefaultSnippets() -> [Snippet] {
        [
            Snippet(
                trigger: ";email",
                replacement: "user@example.com",
                label: "Primary Email Address",
                tags: ["contact", "personal"]
            ),
            Snippet(
                trigger: ";date",
                replacement: "{{date}}",
                label: "Current Today's Date",
                tags: ["dynamic", "datetime"]
            ),
            Snippet(
                trigger: ";time",
                replacement: "{{time}}",
                label: "Current Local Time",
                tags: ["dynamic", "datetime"]
            ),
            Snippet(
                trigger: ";brb",
                replacement: "Be right back!",
                label: "BRB Quick Reply",
                tags: ["chat"]
            ),
            Snippet(
                trigger: ";shrug",
                replacement: "¯\\_(ツ)_/¯",
                label: "Shrug Kaomoji",
                tags: ["emoji"]
            ),
            Snippet(
                trigger: ";sig",
                replacement: "Best regards,\n\nJohn Doe\nSoftware Engineer\n{{date}}",
                label: "Email Signature",
                tags: ["work", "email"]
            )
        ]
    }
}
