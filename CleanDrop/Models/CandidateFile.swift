import Foundation

struct CandidateFile: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    let url: URL
    let displayName: String
    let path: String
    let estimatedSize: Int64
    let confidence: MatchConfidence
    let category: ScanCategory
    let reason: String
    let isRiskyOrShared: Bool
    let isSharedVendorFolder: Bool
    let isSystemLevel: Bool
    let isClearlyAppSpecific: Bool
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        estimatedSize: Int64,
        confidence: MatchConfidence,
        category: ScanCategory,
        reason: String,
        isRiskyOrShared: Bool = false,
        isSharedVendorFolder: Bool = false,
        isSystemLevel: Bool = false,
        isClearlyAppSpecific: Bool = false,
        isSelected: Bool? = nil
    ) {
        self.id = id
        self.url = url
        self.displayName = url.lastPathComponent
        self.path = url.path
        self.estimatedSize = estimatedSize
        self.confidence = confidence
        self.category = category
        self.reason = reason
        self.isRiskyOrShared = isRiskyOrShared
        self.isSharedVendorFolder = isSharedVendorFolder
        self.isSystemLevel = isSystemLevel
        self.isClearlyAppSpecific = isClearlyAppSpecific
        self.isSelected = isSelected ?? CandidateFile.defaultSelection(
            confidence: confidence,
            category: category,
            isRiskyOrShared: isRiskyOrShared,
            isSharedVendorFolder: isSharedVendorFolder,
            isSystemLevel: isSystemLevel,
            isClearlyAppSpecific: isClearlyAppSpecific
        )
    }

    var warningBadgeText: String? {
        if isSharedVendorFolder {
            return "Shared"
        }

        if isSystemLevel {
            return "System-level"
        }

        if isRiskyOrShared {
            return "Risky"
        }

        return nil
    }

    static func defaultSelection(
        confidence: MatchConfidence,
        category: ScanCategory,
        isRiskyOrShared: Bool,
        isSharedVendorFolder: Bool,
        isSystemLevel: Bool,
        isClearlyAppSpecific: Bool
    ) -> Bool {
        guard !isRiskyOrShared, !isSharedVendorFolder, !isSystemLevel else {
            return false
        }

        guard category != .riskyShared else {
            return false
        }

        switch confidence {
        case .high:
            return true
        case .medium:
            return isClearlyAppSpecific
        case .low:
            return false
        }
    }
}
