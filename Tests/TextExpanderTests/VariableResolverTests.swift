import XCTest
@testable import TextExpander

final class VariableResolverTests: XCTestCase {
    func testResolveDateAndCustomDate() {
        let resolver = VariableResolver()
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 30
        let date = Calendar.current.date(from: components)!

        let context = ExpansionContext(date: date)
        let resultCustom = resolver.resolve(template: "Today is {{date:yyyy-MM-dd}}.", context: context)
        XCTAssertEqual(resultCustom.text, "Today is 2026-01-01.")

        let resultDefaultDate = resolver.resolve(template: "{{date}}", context: context)
        XCTAssertEqual(resultDefaultDate.text, "01-Jan-26")

        let resultDefaultDateTime = resolver.resolve(template: "{{datetime}}", context: context)
        XCTAssertEqual(resultDefaultDateTime.text, "01-Jan-26 12:30 PM")
    }

    func testResolveClipboard() {
        let resolver = VariableResolver()
        let context = ExpansionContext(clipboardText: "CopiedText123")
        let result = resolver.resolve(template: "Pasted: {{clipboard}}", context: context)
        XCTAssertEqual(result.text, "Pasted: CopiedText123")
    }

    func testResolveCursorPosition() {
        let resolver = VariableResolver()
        let result = resolver.resolve(template: "Hello {{cursor}} world!")
        XCTAssertEqual(result.text, "Hello  world!")
        XCTAssertEqual(result.cursorOffsetFromEnd, 7)
    }
}
