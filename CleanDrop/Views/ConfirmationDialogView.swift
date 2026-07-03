import SwiftUI

struct ConfirmationDialogView: View {
    let appName: String
    let selectedCount: Int
    let selectedTotalSize: Int64
    let hasRiskySelection: Bool
    let isMoving: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Move Selected Files to Trash")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You are about to move \(selectedCount) selected files/folders to Trash. This action does not permanently delete them, but you should review the list carefully.")
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                detailRow(label: "App", value: appName)
                detailRow(label: "Selected", value: "\(selectedCount)")
                detailRow(label: "Estimated size", value: SizeCalculator.formattedSize(selectedTotalSize))
            }

            if hasRiskySelection {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Your selection includes shared, risky, or system-level items. Confirm only if you are certain these files belong to this app.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Spacer()

                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Move Selected Files to Trash", role: .destructive, action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isMoving || selectedCount == 0)
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
