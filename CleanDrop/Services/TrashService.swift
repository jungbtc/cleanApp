import Foundation

final class TrashService: @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func moveSelectedItemsToTrash(candidates: [CandidateFile], appInfo: AppInfo) -> TrashReport {
        let selectedCandidates = candidates.filter(\.isSelected)
        let skippedCandidates = candidates.filter { !$0.isSelected }
        var movedFiles: [TrashedFile] = []
        var errors: [TrashErrorDetail] = []

        for candidate in selectedCandidates {
            guard fileManager.fileExists(atPath: candidate.path) else {
                errors.append(
                    TrashErrorDetail(
                        path: candidate.path,
                        message: "The item no longer exists at this path."
                    )
                )
                continue
            }

            do {
                var trashedURL: NSURL?
                try fileManager.trashItem(at: candidate.url, resultingItemURL: &trashedURL)

                movedFiles.append(
                    TrashedFile(
                        originalPath: candidate.path,
                        trashedPath: (trashedURL as URL?)?.path,
                        estimatedSize: candidate.estimatedSize
                    )
                )
            } catch {
                errors.append(
                    TrashErrorDetail(
                        path: candidate.path,
                        message: error.localizedDescription
                    )
                )
            }
        }

        var report = TrashReport(
            appInfo: appInfo,
            movedFiles: movedFiles,
            skippedFiles: skippedCandidates,
            errors: errors,
            timestamp: Date(),
            logURL: nil
        )

        report.logURL = try? writeRemovalLog(report)
        return report
    }

    private func writeRemovalLog(_ report: TrashReport) throws -> URL {
        let logsDirectory = try cleanDropLogsDirectory()
        try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        let safeAppName = report.appInfo.displayName
            .map { $0.isLetter || $0.isNumber ? String($0) : "-" }
            .joined()
        let timestamp = ISO8601DateFormatter()
            .string(from: report.timestamp)
            .replacingOccurrences(of: ":", with: "-")
        let logURL = logsDirectory.appendingPathComponent("\(timestamp)-\(safeAppName)-removal.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(report)
        try data.write(to: logURL, options: .atomic)
        return logURL
    }

    private func cleanDropLogsDirectory() throws -> URL {
        if let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first {
            return libraryURL
                .appendingPathComponent("Logs", isDirectory: true)
                .appendingPathComponent("CleanDrop", isDirectory: true)
        }

        throw CocoaError(.fileNoSuchFile)
    }
}
