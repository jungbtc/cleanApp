import Foundation

struct AppInfo: Identifiable, Hashable, Codable, Sendable {
    let bundleURL: URL
    let bundleIdentifier: String?
    let displayName: String
    let bundleName: String
    let executableName: String?
    let vendorName: String?

    var id: String {
        bundleIdentifier ?? bundleURL.path
    }

    var bundlePath: String {
        bundleURL.path
    }

    var appNameCandidates: [String] {
        var names = [
            displayName,
            bundleName,
            bundleURL.deletingPathExtension().lastPathComponent
        ]

        if let executableName, !executableName.isEmpty {
            names.append(executableName)
        }

        var seen = Set<String>()
        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }
}
