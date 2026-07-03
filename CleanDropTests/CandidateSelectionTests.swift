import Foundation
import XCTest
@testable import CleanDrop

final class CandidateSelectionTests: XCTestCase {
    func testHighConfidenceAppSpecificFilesAreSelectedByDefault() {
        let candidate = CandidateFile(
            url: URL(fileURLWithPath: "/Users/example/Library/Preferences/com.example.Demo.plist"),
            estimatedSize: 100,
            confidence: .high,
            category: .preferences,
            reason: "Path contains the full bundle identifier.",
            isClearlyAppSpecific: true
        )

        XCTAssertTrue(candidate.isSelected)
    }

    func testMediumConfidenceFilesStayUncheckedUnlessClearlyAppSpecific() {
        let candidate = CandidateFile(
            url: URL(fileURLWithPath: "/Users/example/Library/Caches/demo-cache"),
            estimatedSize: 100,
            confidence: .medium,
            category: .caches,
            reason: "Path contains a normalized app name.",
            isClearlyAppSpecific: false
        )

        XCTAssertFalse(candidate.isSelected)
    }

    func testLowConfidenceFilesAreNeverSelectedByDefault() {
        let candidate = CandidateFile(
            url: URL(fileURLWithPath: "/Users/example/Library/Application Support/Example"),
            estimatedSize: 100,
            confidence: .low,
            category: .riskyShared,
            reason: "Vendor-only match.",
            isRiskyOrShared: true,
            isSharedVendorFolder: true
        )

        XCTAssertFalse(candidate.isSelected)
    }

    func testRiskySystemLevelFilesAreNeverSelectedByDefault() {
        let candidate = CandidateFile(
            url: URL(fileURLWithPath: "/Library/LaunchDaemons/com.example.Demo.helper.plist"),
            estimatedSize: 100,
            confidence: .high,
            category: .launchAgentsDaemons,
            reason: "Path contains the full bundle identifier.",
            isRiskyOrShared: true,
            isSystemLevel: true,
            isClearlyAppSpecific: true
        )

        XCTAssertFalse(candidate.isSelected)
    }
}
