#!/usr/bin/env bash
# Smoke-test RTL-SDR presence and driver usability.
set -euo pipefail

echo "== rtl_test / tools =="
if ! command -v rtl_test >/dev/null 2>&1; then
  echo "rtl_test not found. On Ubuntu 24.04 install:"
  echo "  sudo apt install -y rtl-sdr librtlsdr2"
  exit 1
fi

echo "rtl_test: $(command -v rtl_test)"
echo "librtlsdr (linked):"
ldd "$(command -v rtl_test)" 2>/dev/null | grep -i rtlsdr || true

if [[ -f /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf ]]; then
  echo "DVB blacklist: present"
else
  echo "DVB blacklist: MISSING — consider:"
  echo "  echo 'blacklist dvb_usb_rtl28xxu' | sudo tee /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf"
fi

echo
echo "== USB devices (RTL / Realtek) =="
lsusb | grep -iE 'realtek|rtl|sdr' || echo "(none matched — is the stick plugged in?)"

echo
echo "== rtl_test -t (short) =="
# -t tuner test; exits non-zero if no device
if rtl_test -t 2>&1; then
  echo
  echo "OK: RTL-SDR responded."
else
  echo
  echo "FAIL: no usable RTL-SDR (unplugged, permissions, or DVB driver holding the device)."
  exit 1
fi
