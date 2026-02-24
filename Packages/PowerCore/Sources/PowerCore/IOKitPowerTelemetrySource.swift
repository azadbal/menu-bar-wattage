import Foundation
import IOKit.ps

public final class IOKitPowerTelemetrySource: PowerTelemetrySource {
    private var notificationSource: CFRunLoopSource?
    private var notificationHandler: (() -> Void)?
    private let smartBatteryReader: AppleSmartBatteryReader

    public init() {
        self.smartBatteryReader = AppleSmartBatteryReader()
    }

    deinit {
        stopNotifications()
    }

    public func readSnapshot(now: Date) throws -> RawPowerSnapshot {
        let powerSourcesInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourcesList = IOPSCopyPowerSourcesList(powerSourcesInfo).takeRetainedValue() as Array

        guard !powerSourcesList.isEmpty else {
            throw PowerTelemetryError.missingPowerSource
        }

        var selectedDescription: [String: Any]?
        var fallbackDescription: [String: Any]?

        for source in powerSourcesList {
            guard let description = IOPSGetPowerSourceDescription(powerSourcesInfo, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            if fallbackDescription == nil {
                fallbackDescription = description
            }

            if SnapshotMapper.isInternalBattery(description) {
                selectedDescription = description
                break
            }
        }

        guard let sourceDescription = selectedDescription ?? fallbackDescription else {
            throw PowerTelemetryError.invalidPowerSourcePayload
        }

        let adapterDetails = readAdapterDetails()
        let smartBattery = smartBatteryReader.readSnapshot()

        return Self.mergedSnapshot(
            sourceDescription: sourceDescription,
            adapterDetails: adapterDetails,
            smartBatterySnapshot: smartBattery,
            now: now
        )
    }

    public func startNotifications(_ onChange: @escaping () -> Void) {
        stopNotifications()
        notificationHandler = onChange

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let runLoopSource = IOPSNotificationCreateRunLoopSource(Self.powerSourceChanged, context)?.takeRetainedValue() else {
            return
        }

        notificationSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, CFRunLoopMode.defaultMode)
    }

    public func stopNotifications() {
        if let notificationSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), notificationSource, CFRunLoopMode.defaultMode)
            self.notificationSource = nil
        }

        notificationHandler = nil
    }

    private func readAdapterDetails() -> [String: Any]? {
        guard let adapterDetails = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        return adapterDetails
    }

    private static let powerSourceChanged: IOPowerSourceCallbackType = { context in
        guard let context else {
            return
        }

        let source = Unmanaged<IOKitPowerTelemetrySource>.fromOpaque(context).takeUnretainedValue()
        source.notificationHandler?()
    }

    static func mergedSnapshot(
        sourceDescription: [String: Any],
        adapterDetails: [String: Any]?,
        smartBatterySnapshot: AppleSmartBatterySnapshot?,
        now: Date
    ) -> RawPowerSnapshot {
        let iopsSnapshot = SnapshotMapper.map(
            sourceDescription: sourceDescription,
            adapterDetails: adapterDetails,
            now: now
        )

        return RawPowerSnapshot(
            batteryCurrentmA: iopsSnapshot.batteryCurrentmA ?? smartBatterySnapshot?.amperagemA,
            batteryVoltagemV: iopsSnapshot.batteryVoltagemV ?? smartBatterySnapshot?.voltagemV,
            isCharging: iopsSnapshot.isCharging ?? smartBatterySnapshot?.isCharging,
            isCharged: iopsSnapshot.isCharged,
            powerSourceState: iopsSnapshot.powerSourceState,
            adapterWatts: iopsSnapshot.adapterWatts,
            timestamp: now
        )
    }
}
