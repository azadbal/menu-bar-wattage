# Release Metadata

Use this copy for the 1.0.0 Mac App Store listing.

## App name

Statusbar Power

## Subtitle

See charging watts in menu bar.

## Description

Statusbar Power is a small, focused menu-bar utility for Apple Silicon Macs.

When a charging adapter reports a wattage, Statusbar Power shows the rounded value directly in the menu bar, such as `94W`. When the Mac is running on battery, it shows `\`. If macOS cannot provide the power state or adapter wattage, it shows `-`.

Click the value to see the current state, enable or disable Launch at Login, or quit the app.

The displayed number is the charging adapter's reported or negotiated wattage exposed by macOS. It is not a measurement of the Mac's real-time total power consumption and is not a guaranteed battery charging rate.

Statusbar Power has no accounts, network requests, analytics, advertising, subscriptions, or in-app purchases.

## Keywords

power, wattage, charger, adapter, battery, menu bar, USB-C, MacBook

## Support URL

https://github.com/azadbal/statusbar_power

## Privacy Policy URL

https://github.com/azadbal/statusbar_power/blob/main/PRIVACY.md

## Review notes

Statusbar Power is a menu-bar-only utility. After launch, the current adapter-reported wattage appears in the menu bar when external power and wattage are available. Disconnecting the charger changes the value to `\` and the menu explains that the Mac is using battery power. If macOS does not provide adapter wattage, the app displays `-` and explains that the wattage is unavailable.

The app uses macOS's public IOKit power-source API (`IOKit.ps`) and App Sandbox. It does not access private AppleSmartBattery APIs, make network requests, collect data, or require an account. Launch at Login is optional.

## App Privacy answers

- Data collection: No
- Data linked to the user: None
- Data used to track the user: None

## Export compliance

The app does not implement encryption beyond the operating system and standard platform services. Complete Apple's export-compliance questionnaire in App Store Connect and follow the answer appropriate to the final submitted build.
