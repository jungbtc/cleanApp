import Combine
import Foundation

@MainActor
final class ScanResultsViewModel: ObservableObject {
    let appInfo: AppInfo
    let permissionIssues: [PermissionIssue]

    @Published var candidates: [CandidateFile]
    @Published var isShowingConfirmation = false
    @Published var isMovingToTrash = false
    @Published var errorMessage: String?

    private let onCompletion: (TrashReport) -> Void

    init(scanResult: ScanResult, onCompletion: @escaping (TrashReport) -> Void) {
        self.appInfo = scanResult.appInfo
        self.candidates = scanResult.candidates
        self.permissionIssues = scanResult.permissionIssues
        self.onCompletion = onCompletion
    }

    var selectedCandidates: [CandidateFile] {
        candidates.filter(\.isSelected)
    }

    var selectedCount: Int {
        selectedCandidates.count
    }

    var selectedTotalSize: Int64 {
        selectedCandidates.reduce(0) { $0 + $1.estimatedSize }
    }

    var totalDetectedSize: Int64 {
        candidates.reduce(0) { $0 + $1.estimatedSize }
    }

    var hasRiskySelection: Bool {
        selectedCandidates.contains { $0.isRiskyOrShared || $0.isSharedVendorFolder || $0.isSystemLevel }
    }

    var availableCategories: [ScanCategory] {
        Set(candidates.map(\.category)).sorted { $0.sortOrder < $1.sortOrder }
    }

    func candidateIndices(for category: ScanCategory) -> [Int] {
        candidates.indices.filter { candidates[$0].category == category }
    }

    func resetRecommendedSelection() {
        for index in candidates.indices {
            let candidate = candidates[index]
            candidates[index].isSelected = CandidateFile.defaultSelection(
                confidence: candidate.confidence,
                category: candidate.category,
                isRiskyOrShared: candidate.isRiskyOrShared,
                isSharedVendorFolder: candidate.isSharedVendorFolder,
                isSystemLevel: candidate.isSystemLevel,
                isClearlyAppSpecific: candidate.isClearlyAppSpecific
            )
        }
    }

    func prepareToMoveSelectedFilesToTrash() {
        guard selectedCount > 0 else {
            errorMessage = "Select at least one file or folder to move to Trash."
            return
        }

        isShowingConfirmation = true
    }

    func cancelConfirmation() {
        isShowingConfirmation = false
    }

    func confirmMoveSelectedFilesToTrash() {
        guard selectedCount > 0, !isMovingToTrash else {
            return
        }

        let candidateSnapshot = candidates
        let appInfoSnapshot = appInfo
        isMovingToTrash = true

        Task {
            let report = await Task.detached(priority: .userInitiated) {
                TrashService().moveSelectedItemsToTrash(candidates: candidateSnapshot, appInfo: appInfoSnapshot)
            }.value

            isMovingToTrash = false
            isShowingConfirmation = false
            onCompletion(report)
        }
    }
}
