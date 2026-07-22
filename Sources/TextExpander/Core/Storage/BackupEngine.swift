import Foundation

/// Handles snippet import, export, backup, and restore operations.
public final class BackupEngine: Sendable {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    /// Exports snippets array into JSON formatted Data.
    public func exportSnippetsData(_ snippets: [Snippet]) throws -> Data {
        try encoder.encode(snippets)
    }

    /// Imports snippets from JSON Data.
    public func importSnippetsData(_ data: Data) throws -> [Snippet] {
        try decoder.decode([Snippet].self, from: data)
    }

    /// Creates a backup file in App Support backups folder.
    public func createBackup(snippets: [Snippet]) throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let backupFolder = appSupport.appendingPathComponent("TextExpander/Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let backupURL = backupFolder.appendingPathComponent("snippets_backup_\(timestamp).json")

        let data = try exportSnippetsData(snippets)
        try data.write(to: backupURL, options: [.atomic])

        return backupURL
    }
}
