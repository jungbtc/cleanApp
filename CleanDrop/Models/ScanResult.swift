import Foundation

struct PermissionIssue: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    let path: String
    let message: String
}

struct ScanResult: Hashable, Codable, Sendable {
    let appInfo: AppInfo
    let candidates: [CandidateFile]
    let permissionIssues: [PermissionIssue]
}

struct TrashedFile: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    let originalPath: String
    let trashedPath: String?
    let estimatedSize: Int64
}

struct TrashErrorDetail: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    let path: String
    let message: String
}

struct TrashReport: Hashable, Codable, Sendable {
    let appInfo: AppInfo
    let movedFiles: [TrashedFile]
    let skippedFiles: [CandidateFile]
    let errors: [TrashErrorDetail]
    let timestamp: Date
    var logURL: URL?

    var movedCount: Int {
        movedFiles.count
    }

    var skippedCount: Int {
        skippedFiles.count
    }

    var totalMovedSize: Int64 {
        movedFiles.reduce(0) { $0 + $1.estimatedSize }
    }
}
