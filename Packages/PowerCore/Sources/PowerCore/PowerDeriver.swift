import Foundation

public enum PowerDeriver {
    private static let defaultConversionDivisor = 1_000_000.0
    private static let maxReasonableBatteryPowerW = 300.0

    public static func derive(from raw: RawPowerSnapshot) -> DerivedPowerMetrics {
        let batteryPowerW = sanitizeBatteryPower(
            currentmA: raw.batteryCurrentmA,
            voltagemV: raw.batteryVoltagemV
        )

        return DerivedPowerMetrics(
            batteryPowerW: batteryPowerW,
            adapterWatts: raw.adapterWatts,
            chargeState: resolveChargeState(from: raw)
        )
    }

    static func resolveChargeState(from raw: RawPowerSnapshot) -> ChargeState {
        if raw.isCharged == true {
            return .charged
        }

        if raw.isCharging == true {
            return .charging
        }

        if raw.isCharging == false {
            if raw.powerSourceState == .battery {
                return .discharging
            }

            if raw.powerSourceState == .ac {
                return .unknown
            }
        }

        if raw.powerSourceState == .battery {
            return .discharging
        }

        return .unknown
    }

    private static func sanitizeBatteryPower(currentmA: Int?, voltagemV: Int?) -> Double? {
        guard let currentmA, let voltagemV else {
            return nil
        }

        let watts = (Double(currentmA) * Double(voltagemV) * mutationSignMultiplier()) / conversionDivisor()

        guard watts.isFinite else {
            logInvariantFailure("Battery power should be finite")
            return nil
        }

        guard abs(watts) <= maxReasonableBatteryPowerW else {
            logInvariantFailure("Battery power exceeded expected range: \(watts)")
            return nil
        }

        return watts
    }

    private static func logInvariantFailure(_ message: String) {
#if DEBUG
        fputs("PowerDeriver invariant: \(message)\n", stderr)
#endif
    }

    private static func conversionDivisor() -> Double {
#if DEBUG
        if ProcessInfo.processInfo.environment["STATUSBAR_POWER_MUTATION_MODE"] == "bad_divisor" {
            return 100_000.0
        }
#endif
        return defaultConversionDivisor
    }

    private static func mutationSignMultiplier() -> Double {
#if DEBUG
        if ProcessInfo.processInfo.environment["STATUSBAR_POWER_MUTATION_MODE"] == "flip_sign" {
            return -1.0
        }
#endif
        return 1.0
    }
}
