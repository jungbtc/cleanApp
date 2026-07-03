import SwiftUI

struct CandidateFileRow: View {
    @Binding var candidate: CandidateFile

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: $candidate.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(candidate.displayName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Badge(text: candidate.confidence.displayName, color: confidenceColor)
                    Badge(text: candidate.category.displayName, color: .secondary)

                    if let warning = candidate.warningBadgeText {
                        Badge(text: warning, color: .orange)
                    }
                }

                Text(candidate.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(SizeCalculator.formattedSize(candidate.estimatedSize))
                        .font(.caption)
                        .fontWeight(.medium)

                    Text(candidate.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
    }

    private var confidenceColor: Color {
        switch candidate.confidence {
        case .high:
            return .green
        case .medium:
            return .blue
        case .low:
            return .gray
        }
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
