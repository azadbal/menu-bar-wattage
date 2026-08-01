# Menu Bar Wattage

Menu Bar Wattage is a macOS menu-bar utility that reports the wattage associated with the connected external power adapter.

The release plan supports both Mac App Store distribution and a notarized Developer ID build attached to a GitHub Release. Direct-distribution binaries belong on GitHub Releases, not in the Git history.

## Power reporting

**External power**:
Power supplied through a connected power adapter. The app treats this as present whenever macOS reports an external power source.

**Adapter wattage**:
The wattage reported by macOS for the connected power adapter. It represents the adapter's reported or negotiated wattage, not the Mac's real-time total power consumption or guaranteed battery charge rate.

**Wattage unavailable**:
The display condition used when external power is connected but macOS does not provide adapter wattage, or when power telemetry is unavailable. The compact status representation is `-`.

**Power status display**:
The compact menu-bar value. It shows rounded adapter wattage while external power is present, `\` while the Mac is running on battery, and `-` only when the power state or adapter wattage is unavailable.
