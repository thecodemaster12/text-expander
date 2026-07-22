import XCTest
@testable import TextExpander

final class SnippetEngineTests: XCTestCase {
    func testLoadAndEvaluateSnippet() async {
        let engine = SnippetEngine()
        let sampleSnippets = [
            Snippet(trigger: ";email", replacement: "test@domain.com", label: "Email"),
            Snippet(trigger: ";brb", replacement: "Be right back!", label: "BRB")
        ]
        await engine.loadSnippets(sampleSnippets)

        var buffer = WordBuffer(capacity: 30)
        for char in "hello ;email" {
            buffer.append(char)
        }

        let match = await engine.evaluateBuffer(buffer)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.snippet.trigger, ";email")
        XCTAssertEqual(match?.expansionResult.text, "test@domain.com")
    }

    func testDisabledSnippetNotEvaluated() async {
        let engine = SnippetEngine()
        let snippet = Snippet(trigger: ";disabled", replacement: "Secret", isEnabled: false)
        await engine.loadSnippets([snippet])

        var buffer = WordBuffer(capacity: 30)
        for char in ";disabled" {
            buffer.append(char)
        }

        let match = await engine.evaluateBuffer(buffer)
        XCTAssertNil(match)
    }

    func testGlobalDisable() async {
        let engine = SnippetEngine()
        let snippet = Snippet(trigger: ";test", replacement: "Result")
        await engine.loadSnippets([snippet])
        await engine.setGloballyEnabled(false)

        var buffer = WordBuffer(capacity: 20)
        for char in ";test" {
            buffer.append(char)
        }

        let match = await engine.evaluateBuffer(buffer)
        XCTAssertNil(match)
    }

    func testLongestTriggerPreferredOverShorterSuffixMatch() async {
        let engine = SnippetEngine()
        // "il" is also a trailing substring of "...email", but the longer, more specific
        // trigger should win rather than an arbitrary dictionary-order pick.
        let sampleSnippets = [
            Snippet(trigger: "il", replacement: "SHORT"),
            Snippet(trigger: ";email", replacement: "LONG")
        ]
        await engine.loadSnippets(sampleSnippets)

        var buffer = WordBuffer(capacity: 30)
        for char in "hi;email" {
            buffer.append(char)
        }

        let match = await engine.evaluateBuffer(buffer)
        XCTAssertEqual(match?.snippet.trigger, ";email")
        XCTAssertEqual(match?.expansionResult.text, "LONG")
    }

    func testUpsertAndDeleteSnippet() async {
        let engine = SnippetEngine()
        let id = UUID()
        let snippet = Snippet(id: id, trigger: ";temp", replacement: "Val")
        let afterUpsert = await engine.upsertSnippet(snippet)
        XCTAssertEqual(afterUpsert.count, 1)

        let afterDelete = await engine.deleteSnippet(id: id)
        XCTAssertEqual(afterDelete.count, 0)
    }
}
