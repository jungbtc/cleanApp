import SwiftUI

struct CompletionReportView: View {
    let report: TrashReport
    let onScanAnother: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    reportSection(title: "Moved to Trash", count: report.movedCount) {
                        ForEach(report.movedFiles) { file in
                            pathRow(primary: file.originalPath, secondary: file.trashedPath)
                        }
                    }

                    reportSection(title: "Skipped", count: report.skippedCount) {
                        ForEach(report.skippedFiles) { file in
                            pathRow(primary: file.path, secondary: "Not selected")
                        }
                    }

                    if !report.errors.isEmpty {
                        reportSection(title: "Errors", count: report.errors.count) {
                            ForEach(report.errors) { error in
                                pathRow(primary: error.path, secondary: error.message)
                            }
                        }
                    }

                    if let logURL = report.logURL {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Removal Log")
                                .font(.headline)
                            Text(logURL.path)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(18)
            }

            Divider()

            HStack {
                Spacer()
                Button("Scan Another App", action: onScanAnother)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Cleanup Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(report.movedCount) moved to Trash, \(report.skippedCount) skipped")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(SizeCalculator.formattedSize(report.totalMovedSize))
                    .font(.headline)
                Text(report.appInfo.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
    }

    private func reportSection<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0, content: content)
                .padding(12)
                .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func pathRow(primary: String, secondary: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(primary)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)

            if let secondary {
                Text(secondary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
