
# Statusbar Power

Statusbar Power is a small macOS menu-bar utility for checking the wattage reported by your connected charging adapter.

<img width="280" height="180" alt="Desktop - 1" src="https://github.com/user-attachments/assets/8e91fa2c-dcdb-416f-aaca-1b7a98326e1f" />

## What the menu-bar value means

- `NNW` — macOS reports external power and a charging-adapter wattage, such as `94W`.
- `\` — the Mac is running on battery. The menu explains: “Using battery power. No charging detected.”
- `-` — the power state or charging-adapter wattage is unavailable.

The wattage is the adapter-reported or negotiated value exposed by macOS. It is not a measurement of the Mac’s real-time total power consumption and is not a guaranteed battery charging rate.

Click the value to see the app name, the current-state explanation, Launch at Login, and Quit.

## Requirements

- Apple Silicon Mac
- macOS 13 or later

## Privacy

Statusbar Power does not make network requests, use analytics, require an account, or collect user data. See the [privacy statement](PRIVACY.md).

## Support

For help or to report a bug, [open a GitHub issue](https://github.com/azadbal/statusbar_power/issues/new). Include your macOS version, Mac model, adapter model/wattage, whether the Mac was plugged in, and what the menu-bar value showed.

Before reporting a problem, you can capture local power-source diagnostics with:

```sh
./scripts/diagnose_live_power.sh
```

Please remove anything you do not want to share before posting diagnostic output.
