import AppKit
import Foundation

enum AppInspectionError: LocalizedError, Equatable {
    case notAnApplication(URL)
    case unreadableBundle(URL)

    var errorDescription: String? {
        switch self {
        case .notAnApplication:
            return "Drop a macOS .app bundle to scan for related files."
        case .unreadableBundle:
            return "CleanDrop could not read the app bundle metadata."
        }
    }
}

final class AppInspector {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func inspectApp(at url: URL) throws -> AppInfo {
        let resolvedURL = url.resolvingSymlinksInPath()
        let values = try? resolvedURL.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])

        guard resolvedURL.pathExtension.lowercased() == "app", values?.isDirectory == true else {
            throw AppInspectionError.notAnApplication(resolvedURL)
        }

        guard let bundle = Bundle(url: resolvedURL) else {
            throw AppInspectionError.unreadableBundle(resolvedURL)
        }

        let info = bundle.infoDictionary ?? [:]
        let fallbackName = resolvedURL.deletingPathExtension().lastPathComponent
        let bundleIdentifier = (info["CFBundleIdentifier"] as? String)?.nilIfEmpty ?? bundle.bundleIdentifier
        let bundleName = (info["CFBundleName"] as? String)?.nilIfEmpty ?? fallbackName
        let displayName = (info["CFBundleDisplayName"] as? String)?.nilIfEmpty ?? bundleName
        let executableName = (info["CFBundleExecutable"] as? String)?.nilIfEmpty
        let vendorName = Self.guessVendorName(bundleIdentifier: bundleIdentifier)

        return AppInfo(
            bundleURL: resolvedURL,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            bundleName: bundleName,
            executableName: executableName,
            vendorName: vendorName
        )
    }

    func isApplicationRunning(_ appInfo: AppInfo) -> Bool {
        NSWorkspace.shared.runningApplications.contains { runningApp in
            if let bundleIdentifier = appInfo.bundleIdentifier,
               runningApp.bundleIdentifier == bundleIdentifier {
                return true
            }

            return runningApp.bundleURL?.standardizedFileURL == appInfo.bundleURL.standardizedFileURL
        }
    }

    func quitApplication(_ appInfo: AppInfo) {
        for runningApp in NSWorkspace.shared.runningApplications {
            if let bundleIdentifier = appInfo.bundleIdentifier,
               runningApp.bundleIdentifier == bundleIdentifier {
                runningApp.terminate()
                continue
            }

            if runningApp.bundleURL?.standardizedFileURL == appInfo.bundleURL.standardizedFileURL {
                runningApp.terminate()
            }
        }
    }

    func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(url)
    }

    private static func guessVendorName(bundleIdentifier: String?) -> String? {
        guard let bundleIdentifier else {
            return nil
        }

        let parts = bundleIdentifier.split(separator: ".").map(String.init)
        guard parts.count >= 2 else {
            return nil
        }

        let ignoredPrefixes: Set<String> = ["com", "org", "net", "io", "co"]
        let candidate = ignoredPrefixes.contains(parts[0].lowercased()) ? parts[1] : parts[0]

        guard !candidate.isEmpty else {
            return nil
        }

        return candidate
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
