import Foundation

struct PermissionService {
    static let fullDiskAccessMessage = "Some folders could not be scanned. macOS may require Full Disk Access for CleanDrop in System Settings > Privacy & Security > Full Disk Access."

    func issue(for path: String, error: Error) -> PermissionIssue {
        PermissionIssue(
            path: path,
            message: "\(error.localizedDescription). \(Self.fullDiskAccessMessage)"
        )
    }

    func unreadableIssue(for path: String) -> PermissionIssue {
        PermissionIssue(
            path: path,
            message: Self.fullDiskAccessMessage
        )
    }
}
