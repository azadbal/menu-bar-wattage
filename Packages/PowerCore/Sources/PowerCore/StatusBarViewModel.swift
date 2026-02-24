import Combine
import Foundation

@MainActor
public final class StatusBarViewModel: ObservableObject {
    @Published public private(set) var statusText: String
    @Published public private(set) var batteryWattsText: String
    @Published public private(set) var adapterWattsText: String
    @Published public private(set) var lastUpdatedText: String
    @Published public private(set) var history: [HistoryPoint]
    @Published public private(set) var errorText: String?

    private let dateFormatter: DateFormatter
    private let wattsFormatter: NumberFormatter

    public init(locale: Locale = .current, timeZone: TimeZone = .current) {
        statusText = "No Data"
        batteryWattsText = "Battery Power: Unavailable"
        adapterWattsText = "Adapter Power: Unavailable"
        lastUpdatedText = "Updated: --"
        history = []

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = "HH:mm:ss"
        self.dateFormatter = dateFormatter

        let wattsFormatter = NumberFormatter()
        wattsFormatter.locale = locale
        wattsFormatter.numberStyle = .decimal
        wattsFormatter.minimumFractionDigits = 1
        wattsFormatter.maximumFractionDigits = 1
        self.wattsFormatter = wattsFormatter
    }

    public func bind(engine: SamplingEngine) {
        engine.onUpdate = { [weak self] update in
            self?.apply(update: update)
        }
    }

    public func apply(update: SamplingUpdate) {
        let derivedMetrics = update.derivedMetrics
        let displayBatteryWatts = update.smoothedBatteryPowerW ?? derivedMetrics?.batteryPowerW

        statusText = statusText(
            chargeState: derivedMetrics?.chargeState ?? .unknown,
            batteryWatts: displayBatteryWatts,
            adapterWatts: derivedMetrics?.adapterWatts
        )
        batteryWattsText = batteryPowerText(from: displayBatteryWatts)
        adapterWattsText = adapterPowerText(from: derivedMetrics?.adapterWatts)
        lastUpdatedText = lastUpdatedText(from: update.lastSampleTimestamp)
        history = update.history
        errorText = update.errorMessage
    }

    private func statusText(chargeState: ChargeState, batteryWatts: Double?, adapterWatts: Int?) -> String {
        switch chargeState {
        case .charging:
            if let batteryWatts {
                return "\(Int(abs(batteryWatts).rounded()))W"
            }

            if let adapterWatts {
                return "\(adapterWatts)W"
            }

            return "No Data"
        case .discharging:
            return "On Battery"
        case .charged:
            return "Charged"
        case .unknown:
            return "No Data"
        }
    }

    private func batteryPowerText(from watts: Double?) -> String {
        guard let watts,
              let formatted = wattsFormatter.string(from: NSNumber(value: watts)) else {
            return "Battery Power: Unavailable"
        }

        return "Battery Power: \(formatted) W"
    }

    private func adapterPowerText(from watts: Int?) -> String {
        guard let watts else {
            return "Adapter Power: Unavailable"
        }

        return "Adapter Power: \(watts) W"
    }

    private func lastUpdatedText(from date: Date?) -> String {
        guard let date else {
            return "Updated: --"
        }

        return "Updated: \(dateFormatter.string(from: date))"
    }
}
