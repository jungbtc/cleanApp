import Foundation

enum ScanCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case applicationBundle
    case preferences
    case caches
    case applicationSupport
    case logs
    case savedState
    case containers
    case launchAgentsDaemons
    case receipts
    case riskyShared
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .applicationBundle:
            return "Application Bundle"
        case .preferences:
            return "Preferences"
        case .caches:
            return "Caches"
        case .applicationSupport:
            return "Application Support"
        case .logs:
            return "Logs"
        case .savedState:
            return "Saved State"
        case .containers:
            return "Containers"
        case .launchAgentsDaemons:
            return "Launch Agents / Daemons"
        case .receipts:
            return "Receipts"
        case .riskyShared:
            return "Risky / Shared"
        case .other:
            return "Other"
        }
    }

    var sortOrder: Int {
        switch self {
        case .applicationBundle:
            return 0
        case .preferences:
            return 1
        case .caches:
            return 2
        case .applicationSupport:
            return 3
        case .logs:
            return 4
        case .savedState:
            return 5
        case .containers:
            return 6
        case .launchAgentsDaemons:
            return 7
        case .receipts:
            return 8
        case .riskyShared:
            return 9
        case .other:
            return 10
        }
    }
}
