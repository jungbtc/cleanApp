import AppKit
import SwiftUI

struct ScanResultsView: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let onScanAnother: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if !viewModel.permissionIssues.isEmpty {
                permissionBanner
                Divider()
            }

            if viewModel.candidates.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.availableCategories) { category in
                            CategorySectionView(viewModel: viewModel, category: category)
                        }
                    }
                    .padding(18)
                }
            }

            Divider()
            footer
        }
        .sheet(isPresented: $viewModel.isShowingConfirmation) {
            ConfirmationDialogView(
                appName: viewModel.appInfo.displayName,
                selectedCount: viewModel.selectedCount,
                selectedTotalSize: viewModel.selectedTotalSize,
                hasRiskySelection: viewModel.hasRiskySelection,
                isMoving: viewModel.isMovingToTrash,
                onCancel: viewModel.cancelConfirmation,
                onConfirm: viewModel.confirmMoveSelectedFilesToTrash
            )
        }
        .alert("CleanDrop", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: viewModel.appInfo.bundlePath))
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.appInfo.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(viewModel.appInfo.bundleIdentifier ?? "No bundle identifier")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(viewModel.appInfo.bundlePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(viewModel.candidates.count) detected")
                    .font(.headline)
                Text(SizeCalculator.formattedSize(viewModel.totalDetectedSize))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Some locations could not be scanned")
                .font(.headline)
            Text(PermissionService.fullDiskAccessMessage)
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(viewModel.permissionIssues.prefix(3)) { issue in
                Text(issue.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.yellow.opacity(0.12))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No related files were found.")
                .font(.title3)
                .fontWeight(.semibold)
            Text("The dropped app bundle is still listed when it can be inspected.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Scan Another App", action: onScanAnother)

            Button("Reset Recommended Selection") {
                viewModel.resetRecommendedSelection()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.selectedCount) selected")
                    .font(.headline)
                Text(SizeCalculator.formattedSize(viewModel.selectedTotalSize))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Move Selected Files to Trash") {
                viewModel.prepareToMoveSelectedFilesToTrash()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.selectedCount == 0 || viewModel.isMovingToTrash)
        }
        .padding(14)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}
