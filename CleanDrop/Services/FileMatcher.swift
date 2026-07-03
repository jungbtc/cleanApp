import Foundation

struct MatchDecision: Hashable, Sendable {
    let confidence: MatchConfidence
    let category: ScanCategory
    let reason: String
    let isRiskyOrShared: Bool
    let isSharedVendorFolder: Bool
    let isSystemLevel: Bool
    let isClearlyAppSpecific: Bool
}

final class FileMatcher: @unchecked Sendable {
    private let sharedPathTerms = [
        "creative cloud",
        "coresync",
        "core sync",
        "adobe desktop service",
        "adobegcclient",
        "licensing",
        "license",
        "updater",
        "update manager",
        "fonts",
        "font",
        "frameworks",
        "framework",
        "slcache",
        "slstore"
    ]

    func match(url: URL, root: URL, defaultCategory: ScanCategory, appInfo: AppInfo) -> MatchDecision? {
        let path = url.standardizedFileURL.path

        guard !path.hasPrefix("/System/") else {
            return nil
        }

        let pathLower = path.lowercased()
        let fileNameLower = url.lastPathComponent.lowercased()
        let fileBaseLower = url.deletingPathExtension().lastPathComponent.lowercased()
        let componentsLower = url.pathComponents.map { $0.lowercased() }
        let appNames = appInfo.appNameCandidates.map { $0.lowercased() }
        let normalizedPath = Self.normalized(path)
        let normalizedAppNames = appInfo.appNameCandidates.map(Self.normalized).filter { $0.count >= 4 }
        let bundleID = appInfo.bundleIdentifier?.lowercased()
        let vendor = appInfo.vendorName?.lowercased()
        let isSystemLevel = path.hasPrefix("/Library/")
        let isSharedVendorFolder = isBroadVendorFolder(url: url, root: root, vendor: vendor)
        let containsSharedTerm = sharedPathTerms.contains { pathLower.contains($0) }
        let riskyOrShared = isSharedVendorFolder || containsSharedTerm || isSystemLevel

        if let bundleID, pathLower.contains(bundleID) {
            return decision(
                confidence: .high,
                category: defaultCategory,
                reason: "Path contains the full bundle identifier \(bundleID).",
                riskyOrShared: riskyOrShared,
                sharedVendor: isSharedVendorFolder,
                systemLevel: isSystemLevel,
                clearlyAppSpecific: true
            )
        }

        if let exactName = appNames.first(where: { componentsLower.contains($0) || fileBaseLower == $0 || fileNameLower == $0 }) {
            return decision(
                confidence: .high,
                category: defaultCategory,
                reason: "Path contains the exact app name or executable name \(exactName).",
                riskyOrShared: riskyOrShared,
                sharedVendor: isSharedVendorFolder,
                systemLevel: isSystemLevel,
                clearlyAppSpecific: true
            )
        }

        if let vendor, hasVendorAndAppSpecificPath(components: componentsLower, vendor: vendor, appNames: appNames) {
            return decision(
                confidence: .high,
                category: defaultCategory,
                reason: "Path is inside a vendor folder and a folder named for this app.",
                riskyOrShared: riskyOrShared,
                sharedVendor: isSharedVendorFolder,
                systemLevel: isSystemLevel,
                clearlyAppSpecific: true
            )
        }

        if let normalizedAppName = normalizedAppNames.first(where: { normalizedPath.contains($0) }) {
            return decision(
                confidence: .medium,
                category: defaultCategory,
                reason: "Path contains the normalized app name \(normalizedAppName).",
                riskyOrShared: riskyOrShared,
                sharedVendor: isSharedVendorFolder,
                systemLevel: isSystemLevel,
                clearlyAppSpecific: normalizedAppNames.contains(Self.normalized(fileBaseLower))
            )
        }

        if let fragmentReason = bundleNameFragmentReason(path: pathLower, appNames: appNames) {
            return decision(
                confidence: .medium,
                category: defaultCategory,
                reason: fragmentReason,
                riskyOrShared: riskyOrShared,
                sharedVendor: isSharedVendorFolder,
                systemLevel: isSystemLevel,
                clearlyAppSpecific: false
            )
        }

        if isSharedVendorFolder, let vendor {
            return MatchDecision(
                confidence: .low,
                category: .riskyShared,
                reason: "Folder only identifies the vendor \(vendor), so it may be shared by multiple apps.",
                isRiskyOrShared: true,
                isSharedVendorFolder: true,
                isSystemLevel: isSystemLevel,
                isClearlyAppSpecific: false
            )
        }

        if containsSharedTerm, let vendor, pathLower.contains(vendor) {
            return MatchDecision(
                confidence: .low,
                category: .riskyShared,
                reason: "Path looks like shared vendor infrastructure rather than files for only this app.",
                isRiskyOrShared: true,
                isSharedVendorFolder: false,
                isSystemLevel: isSystemLevel,
                isClearlyAppSpecific: false
            )
        }

        if let vendor, pathLower.contains(vendor) {
            return MatchDecision(
                confidence: .low,
                category: .riskyShared,
                reason: "Path only matches the vendor name \(vendor), not this specific app.",
                isRiskyOrShared: true,
                isSharedVendorFolder: isSharedVendorFolder,
                isSystemLevel: isSystemLevel,
                isClearlyAppSpecific: false
            )
        }

        return nil
    }

    static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func decision(
        confidence: MatchConfidence,
        category: ScanCategory,
        reason: String,
        riskyOrShared: Bool,
        sharedVendor: Bool,
        systemLevel: Bool,
        clearlyAppSpecific: Bool
    ) -> MatchDecision {
        MatchDecision(
            confidence: confidence,
            category: sharedVendor ? .riskyShared : category,
            reason: reason,
            isRiskyOrShared: riskyOrShared,
            isSharedVendorFolder: sharedVendor,
            isSystemLevel: systemLevel,
            isClearlyAppSpecific: clearlyAppSpecific
        )
    }

    private func isBroadVendorFolder(url: URL, root: URL, vendor: String?) -> Bool {
        guard let vendor else {
            return false
        }

        let relativeComponents = relativeComponents(for: url, from: root).map { $0.lowercased() }
        return relativeComponents.count == 1 && relativeComponents.first == vendor
    }

    private func hasVendorAndAppSpecificPath(components: [String], vendor: String, appNames: [String]) -> Bool {
        guard let vendorIndex = components.firstIndex(of: vendor) else {
            return false
        }

        let appComponents = components[(vendorIndex + 1)...]
        return appNames.contains { appName in
            appComponents.contains(appName)
        }
    }

    private func bundleNameFragmentReason(path: String, appNames: [String]) -> String? {
        for appName in appNames {
            let words = appName
                .split { !$0.isLetter && !$0.isNumber }
                .map { String($0).lowercased() }
                .filter { $0.count >= 3 }

            guard words.count >= 2 else {
                continue
            }

            let matchedWords = words.filter { path.contains($0) }
            if matchedWords.count >= 2 {
                return "Path contains multiple app name fragments: \(matchedWords.joined(separator: ", "))."
            }
        }

        return nil
    }

    private func relativeComponents(for url: URL, from root: URL) -> [String] {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path

        guard path.hasPrefix(rootPath) else {
            return url.pathComponents
        }

        let relative = path.dropFirst(rootPath.count)
        return relative.split(separator: "/").map(String.init)
    }
}
