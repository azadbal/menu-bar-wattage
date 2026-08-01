import PowerCore
import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adapter Power")
                .font(.headline)

            metricRow(label: "Status", value: viewModel.statusText)
            metricRow(label: "Adapter", value: viewModel.adapterWattsText)
            metricRow(label: "Last Updated", value: viewModel.lastUpdatedText)

            if let explanation = viewModel.statusExplanationText {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorText = viewModel.errorText {
                Text("Error: \(errorText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

        }
        .padding(12)
        .frame(width: 300, alignment: .leading)
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text("\(label):")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 85, alignment: .leading)

            Text(value)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
