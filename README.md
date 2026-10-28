# CellularSwitch

**Windows network-technology switcher for laptops with embedded 4G/LTE modems (WWAN / Mobile Broadband).**

Force your laptop's cellular modem onto **3G / HSPA+** (great when local LTE is congested) or back to **LTE/4G**, with a one-click GUI or batch files. No vendor tools, no AT commands — uses the official **Windows Mobile Broadband COM API (`mbnapi`)**, so it works even on OEM modems whose AT ports are firmware-locked.

> Verified on a **Fibocom L830-EB** (Intel XMM family) in a Lenovo laptop on Telkom (South Africa):
> switching from a congested LTE cell (4 Mbps) to DC-HSPA+ gave **~17 Mbps**.

## Why?

On some carriers (e.g. Telkom SA), LTE towers are heavily oversubscribed while the 3G network has spare capacity — so "older" HSPA+ can be several times faster than LTE. Windows has **no built-in UI** to choose the radio technology. This tool uses `IMbnRegistration::SetRegisterMode` with a preferred data-class mask (UMTS/HSDPA/HSUPA, excluding LTE) and re-registers the modem.

## What's in the box

| File | Purpose |
|---|---|
| `Cellular Switcher.bat` | Launches the GUI |
| `Switch to 3G+.bat` | One-click console switch to HSPA+ |
| `Back to LTE.bat` | One-click console switch back to LTE |
| `Cellular-Switcher-GUI.ps1` | WinForms GUI (background-thread switch, live log) |
| `Switch-CellularTech.ps1` | CLI: `status` / `3g` / `lte` |
| `MbnInterop.ps1` | Hand-written C# interop for `mbnapi` (no typelib exists — vtables taken from the Windows SDK header) |

## Usage

Double-click **`Cellular Switcher.bat`**, or from a console:

```powershell
.\Switch-CellularTech.ps1 status   # read-only: current tech, operator, registration
.\Switch-CellularTech.ps1 3g       # prefer HSPA+/3G (disables LTE)  [brief disconnect]
.\Switch-CellularTech.ps1 lte      # prefer LTE/4G (default)         [brief disconnect]
```

The switch takes ~15–25 s (disconnect → re-register → reconnect). The preference **persists across reboots** until changed back.

## Requirements

- Windows 10/11 with a working **Mobile Broadband (WWAN) connection** (embedded or USB modem, `WwanSvc` running)
- A SIM that can register on 3G and LTE (multi-mode modem)
- No admin rights needed

## Notes & limitations

- The MBN API hints the *preferred* data classes; if the modem can't find any of them it falls back to the best available (per the API contract). Result can therefore vary by location.
- Some modems report DC-HSPA+ as `MBN_DATA_CLASS_CUSTOM` (0x80000000) — the tool displays this as-is.
- Developed/tested on Windows 11 + Fibocom L830-EB. Feedback for other modems (Quectel, Sierra, Dell DW-series, Huawei...) is welcome.

## Roadmap

- [ ] SMS send/read via `IMbnSms` (works on AT-locked modems — PDU send/receive confirmed)
- [ ] USSD dialer via `IMbnUssd`
- [ ] Signal-strength display (`IMbnSignal`)

## License

MIT — see [LICENSE](LICENSE).
