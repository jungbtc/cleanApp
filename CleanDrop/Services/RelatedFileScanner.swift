import Foundation

struct ScanRoot: Hashable, Sendable {
    let url: URL
    let category: ScanCategory
}

final class RelatedFileScanner: @unchecked Sendable {
    private let fileManager: FileManager
    private let matcher: FileMatcher
    private let sizeCalculator: SizeCalculator
    private let permissionService: PermissionService
    private let maxDepth: Int
    private let maxItemsPerRoot: Int

    init(
        fileManager: FileManager = .default,
        matcher: FileMatcher = FileMatcher(),
        sizeCalculator: SizeCalculator = SizeCalculator(),
        permissionService: PermissionService = PermissionService(),
        maxDepth: Int = 6,
        maxItemsPerRoot: Int = 20_000
    ) {
        self.fileManager = fileManager
        self.matcher = matcher
        self.sizeCalculator = sizeCalculator
        self.permissionService = permissionService
        self.maxDepth = maxDepth
        self.maxItemsPerRoot = maxItemsPerRoot
    }

    func scan(for appInfo: AppInfo) -> ScanResult {
        var candidatesByPath: [String: CandidateFile] = [:]
        var permissionIssues: [PermissionIssue] = []

        addCandidate(
            CandidateFile(
                url: appInfo.bundleURL,
                estimatedSize: (try? sizeCalculator.size(of: appInfo.bundleURL)) ?? 0,
                confidence: .high,
                category: .applicationBundle,
                reason: "This is the app bundle that was dropped into CleanDrop.",
                isClearlyAppSpecific: true
            ),
            to: &candidatesByPath
        )

        for root in Self.scanRoots(fileManager: fileManager) {
            guard fileManager.fileExists(atPath: root.url.path) else {
                continue
            }

            guard fileManager.isReadableFile(atPath: root.url.path) else {
                permissionIssues.append(permissionService.unreadableIssue(for: root.url.path))
                continue
            }

            scanRoot(root, appInfo: appInfo, candidatesByPath: &candidatesByPath, permissionIssues: &permissionIssues)
        }

        let candidates = candidatesByPath.values.sorted { lhs, rhs in
            if lhs.category.sortOrder != rhs.category.sortOrder {
                return lhs.category.sortOrder < rhs.category.sortOrder
            }

            if lhs.confidence.sortOrder != rhs.confidence.sortOrder {
                return lhs.confidence.sortOrder < rhs.confidence.sortOrder
            }

            return lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
        }

        return ScanResult(appInfo: appInfo, candidates: candidates, permissionIssues: permissionIssues)
    }

    static func scanRoots(fileManager: FileManager = .default) -> [ScanRoot] {
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library", isDirectory: true)

        return [
            ScanRoot(url: library.appendingPathComponent("Application Support", isDirectory: true), category: .applicationSupport),
            ScanRoot(url: library.appendingPathComponent("Caches", isDirectory: true), category: .caches),
            ScanRoot(url: library.appendingPathComponent("Preferences", isDirectory: true), category: .preferences),
            ScanRoot(url: library.appendingPathComponent("Logs", isDirectory: true), category: .logs),
            ScanRoot(url: library.appendingPathComponent("Saved Application State", isDirectory: true), category: .savedState),
            ScanRoot(url: library.appendingPathComponent("Containers", isDirectory: true), category: .containers),
            ScanRoot(url: library.appendingPathComponent("Group Containers", isDirectory: true), category: .containers),
            ScanRoot(url: library.appendingPathComponent("HTTPStorages", isDirectory: true), category: .caches),
            ScanRoot(url: library.appendingPathComponent("WebKit", isDirectory: true), category: .caches),
            ScanRoot(url: library.appendingPathComponent("Cookies", isDirectory: true), category: .caches),
            ScanRoot(url: library.appendingPathComponent("LaunchAgents", isDirectory: true), category: .launchAgentsDaemons),
            ScanRoot(url: library.appendingPathComponent("CrashReporter", isDirectory: true), category: .logs),
            ScanRoot(url: library.appendingPathComponent("Application Scripts", isDirectory: true), category: .applicationSupport),
            ScanRoot(url: URL(fileURLWithPath: "/Library/Application Support", isDirectory: true), category: .applicationSupport),
            ScanRoot(url: URL(fileURLWithPath: "/Library/Caches", isDirectory: true), category: .caches),
            ScanRoot(url: URL(fileURLWithPath: "/Library/Preferences", isDirectory: true), category: .preferences),
            ScanRoot(url: URL(fileURLWithPath: "/Library/Logs", isDirectory: true), category: .logs),
            ScanRoot(url: URL(fileURLWithPath: "/Library/LaunchAgents", isDirectory: true), category: .launchAgentsDaemons),
            ScanRoot(url: URL(fileURLWithPath: "/Library/LaunchDaemons", isDirectory: true), category: .launchAgentsDaemons),
            ScanRoot(url: URL(fileURLWithPath: "/Library/PrivilegedHelperTools", isDirectory: true), category: .launchAgentsDaemons),
            ScanRoot(url: URL(fileURLWithPath: "/Library/Receipts", isDirectory: true), category: .receipts)
        ]
    }

    private func scanRoot(
        _ root: ScanRoot,
        appInfo: AppInfo,
        candidatesByPath: inout [String: CandidateFile],
        permissionIssues: inout [PermissionIssue]
    ) {
        let keys: [URLResourceKey] = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey
        ]

        var rootPermissionIssues: [PermissionIssue] = []

        guard let enumerator = fileManager.enumerator(
            at: root.url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { [permissionService] url, error in
                rootPermissionIssues.append(permissionService.issue(for: url.path, error: error))
                return true
            }
        ) else {
            permissionIssues.append(permissionService.unreadableIssue(for: root.url.path))
            return
        }

        var visited = 0

        for case let url as URL in enumerator {
            visited += 1

            if visited > maxItemsPerRoot {
                break
            }

            let depth = relativeDepth(of: url, from: root.url)
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isSymbolicLink == true {
                if values?.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard let match = matcher.match(url: url, root: root.url, defaultCategory: root.category, appInfo: appInfo) else {
                continue
            }

            let estimatedSize = (try? sizeCalculator.size(of: url)) ?? 0
            let candidate = CandidateFile(
                url: url,
                estimatedSize: estimatedSize,
                confidence: match.confidence,
                category: match.category,
                reason: match.reason,
                isRiskyOrShared: match.isRiskyOrShared,
                isSharedVendorFolder: match.isSharedVendorFolder,
                isSystemLevel: match.isSystemLevel,
                isClearlyAppSpecific: match.isClearlyAppSpecific
            )

            addCandidate(candidate, to: &candidatesByPath)

            if values?.isDirectory == true, !candidate.isSharedVendorFolder {
                enumerator.skipDescendants()
            }
        }

        permissionIssues.append(contentsOf: rootPermissionIssues)
    }

    private func addCandidate(_ candidate: CandidateFile, to candidatesByPath: inout [String: CandidateFile]) {
        let key = candidate.url.standardizedFileURL.path

        if let existing = candidatesByPath[key], existing.confidence.sortOrder <= candidate.confidence.sortOrder {
            return
        }

        candidatesByPath[key] = candidate
    }

    private func relativeDepth(of url: URL, from root: URL) -> Int {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path

        guard path.hasPrefix(rootPath) else {
            return url.pathComponents.count
        }

        return path.dropFirst(rootPath.count).split(separator: "/").count
    }
}
