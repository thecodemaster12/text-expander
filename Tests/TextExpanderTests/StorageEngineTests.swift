import XCTest
@testable import TextExpander

final class StorageEngineTests: XCTestCase {
    var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testSaveAndLoadSnippets() async throws {
        let fileURL = tempDirectory.appendingPathComponent("test_snippets.json")
        let storage = StorageEngine(fileURL: fileURL)

        let initialSnippets = [
            Snippet(trigger: ";test1", replacement: "Value 1"),
            Snippet(trigger: ";test2", replacement: "Value 2")
        ]

        try await storage.saveSnippets(initialSnippets)
        let loaded = try await storage.loadSnippets()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].trigger, ";test1")
        XCTAssertEqual(loaded[1].trigger, ";test2")
    }

    func testBackupEngineExportImport() throws {
        let backupEngine = BackupEngine()
        let snippets = [
            Snippet(trigger: ";test", replacement: "Val")
        ]

        let data = try backupEngine.exportSnippetsData(snippets)
        let imported = try backupEngine.importSnippetsData(data)

        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].trigger, ";test")
    }
}
