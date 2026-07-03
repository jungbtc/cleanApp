import AppKit
import Combine
import Foundation

enum DropState {
    case idle
    case scanning(String?)
    case reviewing(ScanResultsViewModel)
    case completed(TrashReport)
}

@MainActor
final class DropViewModel: ObservableObject {
    @Published var state: DropState = .idle
    @Published var errorMessage: String?
    @Published private(set) var runningAppWarning: AppInfo?

    private let inspector: AppInspector

    init(inspector: AppInspector = AppInspector()) {
        self.inspector = inspector
    }

    func handleDroppedURLs(_ urls: [URL]) {
        guard let url = urls.first else {
            errorMessage = "Drop a macOS .app bundle to scan for related files."
            return
        }

        Task {
            await scanDroppedApp(at: url)
        }
    }

    func reset() {
        state = .idle
        errorMessage = nil
        runningAppWarning = nil
    }

    func dismissRunningWarning() {
        runningAppWarning = nil
    }

    func quitRunningApplication() {
        guard let runningAppWarning else {
            return
        }

        inspector.quitApplication(runningAppWarning)
        self.runningAppWarning = nil
    }

    func openActivityMonitor() {
        inspector.openActivityMonitor()
        runningAppWarning = nil
    }

    private func scanDroppedApp(at url: URL) async {
        state = .scanning(nil)
        errorMessage = nil
        runningAppWarning = nil

        do {
            let appInfo = try inspector.inspectApp(at: url)
            state = .scanning(appInfo.displayName)

            if inspector.isApplicationRunning(appInfo) {
                runningAppWarning = appInfo
            }

            let result = await Task.detached(priority: .userInitiated) {
                RelatedFileScanner().scan(for: appInfo)
            }.value

            let resultsViewModel = ScanResultsViewModel(scanResult: result) { [weak self] report in
                self?.state = .completed(report)
            }

            state = .reviewing(resultsViewModel)
        } catch {
            state = .idle
            errorMessage = error.localizedDescription
        }
    }
}
