import SwiftUI

struct CategorySectionView: View {
    @ObservedObject var viewModel: ScanResultsViewModel
    let category: ScanCategory
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                ForEach(viewModel.candidateIndices(for: category), id: \.self) { index in
                    CandidateFileRow(candidate: $viewModel.candidates[index])

                    if index != viewModel.candidateIndices(for: category).last {
                        Divider()
                            .padding(.leading, 34)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text(category.displayName)
                    .font(.headline)

                Spacer()

                Text("\(viewModel.candidateIndices(for: category).count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
        }
    }
}
