import Foundation
import XCTest
@testable import CleanDrop

final class FileMatcherTests: XCTestCase {
    private let appInfo = AppInfo(
        bundleURL: URL(fileURLWithPath: "/Applications/Adobe After Effects.app"),
        bundleIdentifier: "com.adobe.AfterEffects",
        displayName: "After Effects",
        bundleName: "After Effects",
        executableName: "After Effects",
        vendorName: "Adobe"
    )

    func testBundleIdentifierMatchIsHighConfidenceAndSelectedWhenUserLevel() throws {
        let url = URL(fileURLWithPath: "/Users/example/Library/Preferences/com.adobe.AfterEffects.plist")
        let root = URL(fileURLWithPath: "/Users/example/Library/Preferences", isDirectory: true)

        let match = try XCTUnwrap(FileMatcher().match(url: url, root: root, defaultCategory: .preferences, appInfo: appInfo))
        let candidate = candidate(url: url, match: match)

        XCTAssertEqual(candidate.confidence, .high)
        XCTAssertEqual(candidate.category, .preferences)
        XCTAssertTrue(candidate.reason.contains("bundle identifier"))
        XCTAssertTrue(candidate.isSelected)
    }

    func testSharedVendorFolderIsLowConfidenceRiskyAndUnchecked() throws {
        let url = URL(fileURLWithPath: "/Users/example/Library/Application Support/Adobe", isDirectory: true)
        let root = URL(fileURLWithPath: "/Users/example/Library/Application Support", isDirectory: true)

        let match = try XCTUnwrap(FileMatcher().match(url: url, root: root, defaultCategory: .applicationSupport, appInfo: appInfo))
        let candidate = candidate(url: url, match: match)

        XCTAssertEqual(candidate.confidence, .low)
        XCTAssertEqual(candidate.category, .riskyShared)
        XCTAssertTrue(candidate.isRiskyOrShared)
        XCTAssertTrue(candidate.isSharedVendorFolder)
        XCTAssertFalse(candidate.isSelected)
    }

    func testSystemLevelExactMatchIsWarnedAndUnchecked() throws {
        let url = URL(fileURLWithPath: "/Library/LaunchDaemons/com.adobe.AfterEffects.helper.plist")
        let root = URL(fileURLWithPath: "/Library/LaunchDaemons", isDirectory: true)

        let match = try XCTUnwrap(FileMatcher().match(url: url, root: root, defaultCategory: .launchAgentsDaemons, appInfo: appInfo))
        let candidate = candidate(url: url, match: match)

        XCTAssertEqual(candidate.confidence, .high)
        XCTAssertEqual(candidate.category, .launchAgentsDaemons)
        XCTAssertTrue(candidate.isSystemLevel)
        XCTAssertTrue(candidate.isRiskyOrShared)
        XCTAssertFalse(candidate.isSelected)
    }

    private func candidate(url: URL, match: MatchDecision) -> CandidateFile {
        CandidateFile(
            url: url,
            estimatedSize: 0,
            confidence: match.confidence,
            category: match.category,
            reason: match.reason,
            isRiskyOrShared: match.isRiskyOrShared,
            isSharedVendorFolder: match.isSharedVendorFolder,
            isSystemLevel: match.isSystemLevel,
            isClearlyAppSpecific: match.isClearlyAppSpecific
        )
    }
}
