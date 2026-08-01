import Combine
import Foundation

@MainActor
public final class StatusBarViewModel: ObservableObject {
    @Published public private(set) var statusText: String
    @Published public private(set) var adapterWattsText: String
    @Published public private(set) var statusExplanationText: String?
    @Published public private(set) var lastUpdatedText: String
    @Published public private(set) var errorText: String?

    private let dateFormatter: DateFormatter

    public init(locale: Locale = .current, timeZone: TimeZone = .current) {
        statusText = "-"
        adapterWattsText = "Adapter Power: Unavailable"
        statusExplanationText = "Adapter wattage is unavailable."
        lastUpdatedText = "Updated: --"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = "HH:mm:ss"
        self.dateFormatter = dateFormatter

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
        adapterWattsText = adapterPowerText(from: derivedMetrics?.adapterWatts)
        statusExplanationText = explanationText(
            powerSourceState: derivedMetrics?.powerSourceState,
            adapterWatts: derivedMetrics?.adapterWatts
        )
        lastUpdatedText = lastUpdatedText(from: update.lastSampleTimestamp)
        errorText = update.errorMessage
    }

    private func statusText(powerSourceState: PowerSourceState?, adapterWatts: Int?) -> String {
        guard powerSourceState == .ac, let adapterWatts else {
            return "-"
        }

        return "\(adapterWatts)W"
    }

    private func adapterPowerText(from watts: Int?) -> String {
        guard let watts else {
            return "Adapter Power: Unavailable"
        }

        return "Adapter Power: \(watts) W"
    }

    private func explanationText(powerSourceState: PowerSourceState?, adapterWatts: Int?) -> String? {
        guard powerSourceState != .ac || adapterWatts == nil else {
            return nil
        }

        if powerSourceState == .ac {
            return "Adapter wattage is unavailable."
        }

        return "No external power is connected, so there is no adapter wattage to show."
    }

    private func lastUpdatedText(from date: Date?) -> String {
        guard let date else {
            return "Updated: --"
        }

        return "Updated: \(dateFormatter.string(from: date))"
    }
}
