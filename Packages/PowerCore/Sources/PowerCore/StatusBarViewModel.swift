import Combine
import Foundation

@MainActor
public final class StatusBarViewModel: ObservableObject {
    @Published public private(set) var statusText: String
    @Published public private(set) var statusDetailText: String
    @Published public private(set) var errorText: String?

    public init() {
        statusText = "-"
        statusDetailText = "Power status unavailable."
    }

    public func bind(engine: SamplingEngine) {
        engine.onUpdate = { [weak self] update in
            self?.apply(update: update)
        }
    }

    public func apply(update: SamplingUpdate) {
        let derivedMetrics = update.derivedMetrics

        statusText = statusText(
            powerSourceState: derivedMetrics?.powerSourceState,
            adapterWatts: derivedMetrics?.adapterWatts
        )
        statusDetailText = detailText(
            powerSourceState: derivedMetrics?.powerSourceState,
            adapterWatts: derivedMetrics?.adapterWatts
        )
        errorText = update.errorMessage
    }

    private func statusText(powerSourceState: PowerSourceState?, adapterWatts: Int?) -> String {
        if powerSourceState == .ac, let adapterWatts {
            return "\(adapterWatts)W"
        }

        if powerSourceState == .battery || powerSourceState == .offline {
            return "\\"
        }

        return "-"
    }

    private func detailText(powerSourceState: PowerSourceState?, adapterWatts: Int?) -> String {
        if powerSourceState == .ac, let adapterWatts {
            return "\(adapterWatts)W from charging adapter."
        }

        if powerSourceState == .ac {
            return "Charging adapter wattage unavailable."
        }

        if powerSourceState == .battery || powerSourceState == .offline {
            return "Using battery power. No charging detected."
        }

        return "Power status unavailable."
    }

}
