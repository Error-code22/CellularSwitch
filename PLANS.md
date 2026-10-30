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
- **Must bind the probe to the Cellular interface** (or require WiFi off) — otherwise it measures the wrong adapter, as happened to us on 2026-10-30
- If LTE throughput < threshold for K consecutive probes → switch to 3G+; switch back when LTE recovers
- Consider latency in the decision too: on 2026-10-30, congested LTE was 130–320 ms ping vs 50–90 ms on 3G
- Hysteresis + cooldown to avoid flapping; log to CSV for later analysis
- Runs from tray or hidden window

### 4. Manual network selection ("blackout mode")
- `SetRegisterMode(MANUAL, providerId, ...)` to force registration on a specific operator
- Real use case: during load shedding, Telkom's LTE sites die early (weak battery backup) while 3G (which rides on MTN) stays up — being able to manually pick MTN/Vodacom could restore service
- **⚠️ Learned 2026-10-30:** `ScanNetwork`/`GetVisibleProviders` is **firmware-blocked** on the L830-EB (accepted while attached → `0xC0040002`-style refusal; disconnected → request OK but results never arrive). Windows' "Choose a cellular network" UI is hidden for the same reason. So manual mode must use *known* provider IDs (Telkom=65502, MTN=65510, Vodacom=65501) without a scan UI — test blind manual registration during the next blackout.
- Also: `netsh mbn connect` syntax needs `connmode=name` for stored profiles.

### 5. Signal & cell display (`IMbnSignal`, `IMbnRadio`)
- RSSI / error rate in the GUI
- Radio on/off toggle

## Someday / ideas
- Multi-interface support (USB dongles, several modems)
- Band-level locking (needs modem-specific vendor ops — likely blocked by OEM AT lockdown)
- Single self-contained .exe (package PS + interop with ps2exe or a small C# host)
- Code signing to remove SmartScreen warnings
- Localization (at least nl/af for the SA audience 😄)
