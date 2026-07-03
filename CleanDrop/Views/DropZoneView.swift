import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var viewModel: DropViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 18) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 52, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)

                Text("Drop a macOS app here")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("CleanDrop will scan related files and show a review list before anything can be moved to Trash.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }
            .frame(maxWidth: 620, minHeight: 320)
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color(nsColor: .windowBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isTargeted ? Color.accentColor : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop(providers:))

            Spacer()
        }
        .padding(40)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            viewModel.errorMessage = "Drop a macOS .app bundle to scan for related files."
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?

            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = item as? URL
            }

            DispatchQueue.main.async {
                if let url {
                    viewModel.handleDroppedURLs([url])
                } else {
                    viewModel.errorMessage = "CleanDrop could not read that dropped item."
                }
            }
        }

        return true
    }
}
