import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DropViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                DropZoneView(viewModel: viewModel)
            case .scanning(let appName):
                scanningView(appName: appName)
            case .reviewing(let resultsViewModel):
                ScanResultsView(viewModel: resultsViewModel, onScanAnother: viewModel.reset)
            case .completed(let report):
                CompletionReportView(report: report, onScanAnother: viewModel.reset)
            }
        }
        .frame(minWidth: 900, minHeight: 640)
        .alert("CleanDrop", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("App Is Running", isPresented: runningWarningBinding) {
            Button("Quit App") {
                viewModel.quitRunningApplication()
            }
            Button("Open Activity Monitor") {
                viewModel.openActivityMonitor()
            }
            Button("Continue Review", role: .cancel) {
                viewModel.dismissRunningWarning()
            }
        } message: {
            Text("\(viewModel.runningAppWarning?.displayName ?? "This app") appears to be running. Quit it before moving related files to Trash to avoid partial cleanup.")
        }
    }

    private func scanningView(appName: String?) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text(appName.map { "Scanning \($0)" } ?? "Reading app metadata")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No files will be moved to Trash until you review the results and confirm.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(48)
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

    private var runningWarningBinding: Binding<Bool> {
        Binding(
            get: { viewModel.runningAppWarning != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissRunningWarning()
                }
            }
        )
    }
}
