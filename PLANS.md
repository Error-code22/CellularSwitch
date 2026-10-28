# PLANS — CellularSwitch roadmap & ideas

Living document. Items are roughly in priority order; check things off as they land.

## v1.x — shipped
- [x] **v1.0** LTE ↔ 3G/HSPA+ technology switcher (GUI + CLI + one-click bats)
- [x] **v1.1** Handle `CUSTOM (0x80000000)` data-class reporting quirk (Fibocom firmware), longer settle time, field-test results
- [x] **v1.2** `watch` watchdog mode: auto-bounces the radio when registration is lost (load shedding / no-service recovery)

## Next up
### 1. SMS support (`IMbnSms`)
- Send + read + delete SMS via Windows' Mobile Broadband API (PDU + text modes)
- The target modem (Fibocom L830-EB) already confirmed `PDU receive / PDU send` capability over MBIM — no AT port needed (its AT port is firmware-locked: `+CME Error: PACM(AP),NOT_ALLOWED`)
- CLI first (`sms send <number> <text>`, `sms list`, `sms read <index>`), then a GUI tab
- Long/multipart SMS reassembly

### 2. USSD dialer (`IMbnUssd`)
- Dial `*188#`-style codes (balance checks etc.) straight from the laptop
- Modem reports `MBN_CTRL_CAPS_USSD` = supported
- Needs session handling (new/closed/timeout states) + response decoding

### 3. Auto-switcher ("congestion pilot") — candidate for v2.0
- Background watcher that speed-probes every N minutes (small download from a CDN)
- If LTE throughput < threshold (e.g. 8 Mbps) for K consecutive probes → switch to 3G+
- If on 3G+ and LTE becomes faster again → switch back
- Hysteresis + cooldown to avoid flapping; log to CSV for later analysis
- Runs from tray or hidden window

### 4. Manual network selection ("blackout mode")
- `SetRegisterMode(MANUAL, providerId, ...)` to force registration on a specific operator
- Real use case: during load shedding, Telkom's LTE sites die early (weak battery backup) while 3G (which rides on MTN) stays up — being able to manually pick MTN/Vodacom could restore service
- Needs a scan UI (`IMbnInterface::ScanNetwork` + `GetVisibleProviders`) to list available networks with their IDs
- **Test during next blackout:** does 3G-only keep service? does manual MTN registration work?

### 5. Signal & cell display (`IMbnSignal`, `IMbnRadio`)
- RSSI / error rate in the GUI
- Radio on/off toggle

## Someday / ideas
- Multi-interface support (USB dongles, several modems)
- Band-level locking (needs modem-specific vendor ops — likely blocked by OEM AT lockdown)
- Single self-contained .exe (package PS + interop with ps2exe or a small C# host)
- Code signing to remove SmartScreen warnings
- Localization (at least nl/af for the SA audience 😄)
