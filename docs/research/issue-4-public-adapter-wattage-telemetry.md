# Issue #4 research: public adapter-wattage telemetry for Apple Silicon App Store builds

**Date:** 2026-08-01  
**Issue:** [#4](https://github.com/azadbal/statusbar_power/issues/4)  
**Scope:** Apple primary sources only: Apple Developer documentation, the installed Apple SDK headers, and Apple’s App Store rules. No production source was modified.

## Decision summary

The `IOKit.ps` path is a documented/public macOS API surface and is compatible with the App Store’s public-API rule. Apple’s documentation does **not** promise that an adapter dictionary or its `Watts` key is populated on every machine or accessory, so the value must remain optional. The evidence supports keeping this path in a sandboxed Mac App Store build, but it does not by itself prove uniform runtime behavior across every Apple Silicon Mac, OS release, and adapter; leave the issue open pending signed on-device validation.

## Findings

### API semantics

- `IOPowerSources.h` is the documented IOKit power-source interface. Apple describes it as providing uniform access to attached power-source state, with snapshots, power-source descriptions, the current providing source, and change notifications. Its documented power-source set currently includes batteries and UPS devices. [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h)

- `IOPSGetProvidingPowerSourceType(snapshot)` answers **which source the computer is currently drawing from**, returning AC power, battery power, or UPS power. It is a source-state API, not a wattage API. [IOPSGetProvidingPowerSourceType](https://developer.apple.com/documentation/iokit/iopowersources_h/1810316-iopsgetprovidingpowersourcetype)

- `kIOPSACPowerValue` means the power source is connected to external/AC power and is not draining the internal battery. This is the appropriate external-power state signal. [kIOPSACPowerValue](https://developer.apple.com/documentation/iokit/kiopsacpowervalue)

- `IOPSCopyExternalPowerAdapterDetails()` returns a dictionary describing the attached AC adapter. Apple specifies `NULL` when no adapter is attached or an error occurs, and says callers must release a successful copy. [IOPSCopyExternalPowerAdapterDetails](https://developer.apple.com/documentation/iokit/1523866-iopscopyexternalpoweradapterdeta)

- `kIOPSPowerAdapterWattsKey` identifies the adapter’s wattage. Apple specifies a `CFNumberRef` integer in watts, but explicitly says the key may be absent from the adapter-details dictionary. [kIOPSPowerAdapterWattsKey](https://developer.apple.com/documentation/iokit/kiopspoweradapterwattskey)

- These are separate signals: the provider-type call says whether the Mac is currently drawing from AC, battery, or UPS; the adapter-details call describes an attached AC adapter and may provide its wattage. Therefore, an AC result does not guarantee a non-`NULL` adapter dictionary or a `Watts` entry. This conclusion follows directly from Apple documenting the APIs independently and allowing missing adapter data. [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h), [IOPSCopyExternalPowerAdapterDetails](https://developer.apple.com/documentation/iokit/1523866-iopscopyexternalpoweradapterdeta), [kIOPSPowerAdapterWattsKey](https://developer.apple.com/documentation/iokit/kiopspoweradapterwattskey)

- Apple’s documented meaning is adapter wattage, not total Mac input power, instantaneous battery charge power, or a guarantee of charge rate. That labeling boundary is an inference from the API’s stated subject—the **external AC power adapter**—and Apple does not define this key as a real-time system-consumption measurement. [kIOPSPowerAdapterWattsKey](https://developer.apple.com/documentation/iokit/kiopspoweradapterwattskey)

### Fully charged and missing-data behavior

- Apple defines `kIOPSIsChargedKey` as the battery’s charged state and notes that a battery can be plugged in, not charging, and still be considered charged (for example, at capacity of 95% or greater). This does not redefine the adapter API or imply that adapter wattage must disappear. [kIOPSIsChargedKey](https://developer.apple.com/documentation/iokit/kiopsischargedkey)

- The safe product behavior is therefore: show adapter watts only when the external-power state and optional adapter `Watts` value are present; show an unavailable state when the adapter dictionary is `NULL`, when `Watts` is absent, or when the system is on battery. Do not convert missing data into zero. The missing-value cases are explicit in Apple’s API contract. [IOPSCopyExternalPowerAdapterDetails](https://developer.apple.com/documentation/iokit/1523866-iopscopyexternalpoweradapterdeta), [kIOPSPowerAdapterWattsKey](https://developer.apple.com/documentation/iokit/kiopspoweradapterwattskey)

### Public availability and Apple Silicon

- Apple publishes these symbols under the IOKit framework and the `IOPowerSources.h` / `IOPSKeys.h` documentation, rather than as private or undocumented registry properties. Apple’s current documentation metadata lists `IOPSCopyExternalPowerAdapterDetails` as available on macOS 10.6 and later, `kIOPSPowerAdapterWattsKey` on macOS 10.6 and later, and `IOPSGetProvidingPowerSourceType` on macOS 10.7 and later. [IOKit](https://developer.apple.com/documentation/iokit), [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h), [adapter API availability metadata](https://developer.apple.com/tutorials/data/documentation/iokit/1523866-iopscopyexternalpoweradapterdeta.json), [Watts-key availability metadata](https://developer.apple.com/tutorials/data/documentation/iokit/kiopspoweradapterwattskey.json), [provider-type availability metadata](https://developer.apple.com/tutorials/data/documentation/iokit/1523858-iopsgetprovidingpowersourcetype.json)

- The current Mac SDK installed with Xcode exposes the same functions and key in `IOKit.framework`’s public `ps` headers, and the framework exports the adapter and provider symbols. This is local SDK confirmation of the public build surface; the normative public-API and submission requirements are Apple’s published documentation and agreement below. [IOKit](https://developer.apple.com/documentation/iokit), [IOPowerSources.h](https://developer.apple.com/documentation/iokit/iopowersources_h), [IOPSKeys definitions](https://developer.apple.com/documentation/iokit/iopskeys_h/defines)

- No Apple source found in this review states that these documented power-source APIs are unavailable on Apple Silicon or require an architecture-specific entitlement. That supports API compatibility, not a guarantee of identical telemetry on every Apple Silicon hardware/OS combination. Apple’s guidance still requires testing macOS apps on the target hardware and handling unavailable features with a reasonable fallback. [Porting your macOS apps to Apple silicon](https://developer.apple.com/documentation/apple-silicon/porting-your-macos-apps-to-apple-silicon), [Running code on a specific platform or OS version](https://developer.apple.com/documentation/xcode/running-code-on-a-specific-version)

### Sandboxing and Mac App Store submission

- Apple requires App Sandbox for Mac App Store distribution. Apple’s documented list of activities incompatible with App Sandbox includes operations such as loading kernel extensions, arbitrary Apple Events, and changing network settings; it does not identify the documented IOKit power-source calls as an incompatible activity or specify a power-source entitlement. This is positive evidence for compatibility, but not a promise that every future OS implementation will return every optional field. [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), [Protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox)

- App Review Guideline 2.4.5 requires Mac App Store apps to be appropriately sandboxed and packaged with Xcode as self-contained app bundles. Guideline 2.5.1 requires public APIs and the currently shipping OS. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

- Apple’s Developer Program Agreement is more specific: submitted apps may use documented APIs in Apple’s prescribed manner, may not call private APIs, and macOS App Store apps may use documented APIs included in macOS or the Xcode Mac SDK. The documented IOKit power-source APIs fit that rule. [Apple Developer Program License Agreement, §3.3.1](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)

- For review, explain that the app reports Apple’s adapter-reported wattage and handles absent adapter data; if the feature is difficult for review to reproduce, Apple’s review guidance recommends supplying the relevant configuration or a demo video. [App Review](https://developer.apple.com/app-store/review/)

## Repository fit

The current production reader imports `IOKit.ps`, obtains power-source snapshots/descriptions, calls `IOPSCopyExternalPowerAdapterDetails()`, and maps the optional `kIOPSPowerAdapterWattsKey`; it does not use a private IORegistry fallback in the inspected production path. [IOKitPowerTelemetrySource.swift](../../Packages/PowerCore/Sources/PowerCore/IOKitPowerTelemetrySource.swift) [SnapshotMapper.swift](../../Packages/PowerCore/Sources/PowerCore/SnapshotMapper.swift)

The current app entitlements contain App Sandbox, and the repository’s App Store readiness policy already describes adapter power as an adapter-reported readout rather than guaranteed charge rate. [StatusbarPowerApp.entitlements](../../StatusbarPowerApp/Resources/StatusbarPowerApp.entitlements) [App Store readiness checklist](../app_store_readiness.md)

## Recommendation

Keep the documented `IOKit.ps` implementation for the Store build. Treat `IOPSCopyExternalPowerAdapterDetails()` and `kIOPSPowerAdapterWattsKey` as optional, display an unavailable state for absent data, and describe the metric as adapter-reported watts. Do not add private IOKit/IORegistry access. Before closing issue #4, validate an archived/signed sandboxed arm64 build on Apple Silicon across: external AC connected, fully charged/not charging, adapter details absent, `Watts` absent, and unplugged/battery states. The API/submission decision is favorable; cross-hardware telemetry reliability remains an empirical release gate rather than something Apple’s documentation guarantees.
