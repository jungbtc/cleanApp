import Foundation
import XCTest
@testable import CleanDrop

final class AppInspectorTests: XCTestCase {
    func testInspectAppExtractsBundleMetadata() throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appURL = tempDirectory.appendingPathComponent("Demo.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)

        try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
        addTeardownBlock {
            var trashedURL: NSURL?
            try? fileManager.trashItem(at: tempDirectory, resultingItemURL: &trashedURL)
        }

        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.example.Demo",
            "CFBundleName": "Demo Bundle",
            "CFBundleDisplayName": "Demo App",
            "CFBundleExecutable": "DemoExecutable",
            "CFBundlePackageType": "APPL"
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))

        let appInfo = try AppInspector().inspectApp(at: appURL)

        XCTAssertEqual(appInfo.bundleIdentifier, "com.example.Demo")
        XCTAssertEqual(appInfo.bundleName, "Demo Bundle")
        XCTAssertEqual(appInfo.displayName, "Demo App")
        XCTAssertEqual(appInfo.executableName, "DemoExecutable")
        XCTAssertEqual(appInfo.vendorName, "Example")
        XCTAssertEqual(appInfo.bundleURL.path, appURL.path)
    }

    func testInspectAppRejectsNonAppBundles() {
        let url = URL(fileURLWithPath: "/tmp/not-an-app.txt")

        XCTAssertThrowsError(try AppInspector().inspectApp(at: url)) { error in
            guard case .notAnApplication = error as? AppInspectionError else {
                return XCTFail("Expected notAnApplication, got \(error)")
            }
        }
    }
}
