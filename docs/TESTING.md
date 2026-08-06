# Help test experimental devices

iRazer lists ~190 Razer devices whose protocol is known but **untested on macOS**.
If you own one, you can help move it from ⚗️ *experimental* to ✅ *tested* in a few minutes.

## What "experimental" means

The command protocol comes from the Razer/OpenRazer/OpenRGB database, so iRazer
*probably* speaks your device's language — but nobody has confirmed it on a Mac yet.
macOS has its own quirks (which HID interface/report to use, USB vs Bluetooth), so a
device can: work fully, work partially, do nothing, or behave oddly. Testing tells us which.

**It's safe to try** — iRazer only talks to Razer devices you've plugged in, runs in
userspace (no kernel extension, no root), and can't harm the hardware. Worst case a
command does nothing.

## How to test (5 minutes)

1. Install iRazer and plug in your device.
2. Open iRazer — your device should show as **Detected · Experimental** (green/amber dot).
3. Try the controls shown for it (lighting, brightness, etc.) and note what happens.
4. Grab basic device info for the report:
   ```bash
   .build/debug/nommoctl list      # VID/PID + report sizes
   .build/debug/nommoctl info      # descriptors
   .build/debug/nommoble scan      # if it's wireless/Bluetooth
   ```
5. **File a report:** open the app's device page and click **“Report a test result,”**
   or use the [device test report issue template](https://github.com/hanley-tech/iRazer/issues/new?template=device_test_report.yml).

## For deeper help (captures)

If a control doesn't work, a **packet capture** of the official software talking to the
device is the gold standard — it lets us fix it exactly. See
[ADDING_DEVICES.md](ADDING_DEVICES.md) for how to capture USB (Windows + Synapse) or
Bluetooth (Android HCI snoop / nRF Sniffer) traffic.

## What happens next

Confirmed-working devices graduate to ✅ **tested** in [DEVICES.md](DEVICES.md) and get
their capabilities marked verified in the app. Thanks for helping cover the whole lineup!
