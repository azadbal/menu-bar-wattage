import Charts
import PowerCore
import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Charging Power")
                .font(.headline)

            metricRow(label: "Status", value: viewModel.statusText)
            metricRow(label: "Battery", value: viewModel.batteryWattsText)
            metricRow(label: "Adapter", value: viewModel.adapterWattsText)
            metricRow(label: "Last Updated", value: viewModel.lastUpdatedText)

            if let errorText = viewModel.errorText {
                Text("Error: \(errorText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            chartSection
                .frame(height: 130)
        }
        .padding(12)
        .frame(width: 360, alignment: .leading)
    }

    @ViewBuilder
    private var chartSection: some View {
        if viewModel.history.isEmpty {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.12))
                .overlay(
                    Text("30-minute battery power history appears here")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                )
        } else {
            Chart(viewModel.history, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Battery W", point.batteryPowerW)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
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
