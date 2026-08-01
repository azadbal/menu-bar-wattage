import Foundation

public protocol PowerTelemetrySource: AnyObject {
    func readSnapshot(now: Date) throws -> RawPowerSnapshot
    func startNotifications(_ onChange: @escaping () -> Void)
    func stopNotifications()
}

public extension PowerTelemetrySource {
    func stopNotifications() {}
}

public enum PowerSourceState: String, Codable, Equatable, Sendable {
    case ac
    case battery
    case offline
    case unknown
}

public enum ChargeState: String, Codable, Equatable, Sendable {
    case charging
    case discharging
    case charged
    case unknown
}

public struct RawPowerSnapshot: Codable, Equatable, Sendable {
    public let batteryCurrentmA: Int?
    public let batteryVoltagemV: Int?
    public let isCharging: Bool?
    public let isCharged: Bool?
    public let powerSourceState: PowerSourceState?
    public let adapterWatts: Int?
    public let timestamp: Date

    public init(
        batteryCurrentmA: Int?,
        batteryVoltagemV: Int?,
        isCharging: Bool?,
        isCharged: Bool?,
        powerSourceState: PowerSourceState?,
        adapterWatts: Int?,
        timestamp: Date
    ) {
        self.batteryCurrentmA = batteryCurrentmA
        self.batteryVoltagemV = batteryVoltagemV
        self.isCharging = isCharging
        self.isCharged = isCharged
        self.powerSourceState = powerSourceState
        self.adapterWatts = adapterWatts
        self.timestamp = timestamp
    }
}

public struct DerivedPowerMetrics: Equatable, Sendable {
    public let batteryPowerW: Double?
    public let adapterWatts: Int?
    public let chargeState: ChargeState
    public let powerSourceState: PowerSourceState?

    public init(
        batteryPowerW: Double?,
        adapterWatts: Int?,
        chargeState: ChargeState,
        powerSourceState: PowerSourceState? = nil
    ) {
        self.batteryPowerW = batteryPowerW
        self.adapterWatts = adapterWatts
        self.chargeState = chargeState
        self.powerSourceState = powerSourceState
    }
}

public enum PowerTelemetryError: Error, Equatable {
    case missingPowerSource
    case invalidPowerSourcePayload
}

public struct SamplingUpdate: Sendable {
    public let rawSnapshot: RawPowerSnapshot?
    public let derivedMetrics: DerivedPowerMetrics?
    public let lastSampleTimestamp: Date?
    public let errorMessage: String?

    public init(
        rawSnapshot: RawPowerSnapshot?,
        derivedMetrics: DerivedPowerMetrics?,
        lastSampleTimestamp: Date?,
        errorMessage: String?
    ) {
        self.rawSnapshot = rawSnapshot
        self.derivedMetrics = derivedMetrics
        self.lastSampleTimestamp = lastSampleTimestamp
        self.errorMessage = errorMessage
    }
}
