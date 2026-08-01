import PowerCore
import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Menu Bar Wattage")
                .font(.headline)

            Text(viewModel.statusDetailText)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .frame(width: 260, alignment: .leading)
    }
}
