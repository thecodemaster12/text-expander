import XCTest
@testable import TextExpander

final class WordBufferTests: XCTestCase {
    func testAppendAndCurrentString() {
        var buffer = WordBuffer(capacity: 10)
        buffer.append("a")
        buffer.append("b")
        buffer.append("c")
        XCTAssertEqual(buffer.currentString, "abc")
    }

    func testDeleteLast() {
        var buffer = WordBuffer(capacity: 10)
        buffer.append("h")
        buffer.append("i")
        buffer.deleteLast()
        XCTAssertEqual(buffer.currentString, "h")
    }

    func testSlidingWindowCapacity() {
        var buffer = WordBuffer(capacity: 5)
        for char in "1234567" {
            buffer.append(char)
        }
        XCTAssertEqual(buffer.currentString, "34567")
    }

    func testTriggerMatchingCaseInsensitive() {
        var buffer = WordBuffer(capacity: 20)
        for char in "hello ;email" {
            buffer.append(char)
        }
        XCTAssertTrue(buffer.matchesTrigger(";email", caseSensitive: false))
        XCTAssertTrue(buffer.matchesTrigger(";EMAIL", caseSensitive: false))
    }

    func testTriggerMatchingCaseSensitive() {
        var buffer = WordBuffer(capacity: 20)
        for char in "hello ;EMAIL" {
            buffer.append(char)
        }
        XCTAssertFalse(buffer.matchesTrigger(";email", caseSensitive: true))
        XCTAssertTrue(buffer.matchesTrigger(";EMAIL", caseSensitive: true))
    }

    func testEscapeBackslashSuppression() {
        var buffer = WordBuffer(capacity: 20)
        for char in "hello \\;email" {
            buffer.append(char)
        }
        // Since there is a backslash before ;email, matching should return false
        XCTAssertFalse(buffer.matchesTrigger(";email", caseSensitive: false))
    }
}
