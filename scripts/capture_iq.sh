#!/usr/bin/env bash
# Capture IQ with rtl_sdr into a session raw/ folder and update session.json.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FREQ_HZ=868000000
SAMPLE_RATE=2048000
GAIN=0
DURATION_S=10
LABEL="capture"
SESSION_REL=""

usage() {
  cat <<EOF
Usage: $0 <session-dir> [options]

  <session-dir>   Path relative to repo root or absolute, e.g. sessions/2026-07-16_first-listen

Options:
  --frequency HZ   Center frequency (default: ${FREQ_HZ})
  --rate HZ        Sample rate (default: ${SAMPLE_RATE})
  --gain DB        rtl_sdr -g value; 0 = auto (default: ${GAIN})
  --duration SEC   Capture length in seconds (default: ${DURATION_S})
  --label NAME     Filename label (default: ${LABEL})

Example:
  $0 sessions/2026-07-16_first-listen --duration 15 --label hvpro-button
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

SESSION_REL="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --frequency) FREQ_HZ="$2"; shift 2 ;;
    --rate) SAMPLE_RATE="$2"; shift 2 ;;
    --gain) GAIN="$2"; shift 2 ;;
    --duration) DURATION_S="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ "${SESSION_REL}" != /* ]]; then
  SESSION_DIR="${ROOT}/${SESSION_REL}"
else
  SESSION_DIR="${SESSION_REL}"
fi

RAW_DIR="${SESSION_DIR}/raw"
META="${SESSION_DIR}/session.json"

if [[ ! -d "${RAW_DIR}" ]]; then
  echo "Missing session raw/ dir: ${RAW_DIR}"
  echo "Create one with: ./scripts/new_session.sh <slug> \"scenario\""
  exit 1
fi

if ! command -v rtl_sdr >/dev/null 2>&1; then
  echo "rtl_sdr not found. Install: sudo apt install -y rtl-sdr librtlsdr2"
  exit 1
fi

# samples = rate * duration (rtl_sdr -n is sample count; 2 bytes/sample I+Q for default cu8? 
# rtl_sdr default output is unsigned 8-bit IQ interleaved → 2 bytes per complex sample.
# -n counts complex samples.)
SAMPLES=$(( SAMPLE_RATE * DURATION_S ))
STAMP="$(date +%Y-%m-%d_%H%M%S)"
OUT_NAME="${STAMP}_${LABEL}.cu8"
OUT_PATH="${RAW_DIR}/${OUT_NAME}"

echo "Capturing → ${OUT_PATH}"
echo "  freq=${FREQ_HZ} rate=${SAMPLE_RATE} gain=${GAIN} duration=${DURATION_S}s samples=${SAMPLES}"

rtl_sdr -f "${FREQ_HZ}" -s "${SAMPLE_RATE}" -g "${GAIN}" -n "${SAMPLES}" "${OUT_PATH}"

BYTES="$(wc -c < "${OUT_PATH}" | tr -d ' ')"
echo "Wrote ${BYTES} bytes"

if [[ -f "${META}" ]]; then
  python3 - "${META}" "${OUT_NAME}" "${FREQ_HZ}" "${SAMPLE_RATE}" "${GAIN}" <<'PY'
import json, sys
from pathlib import Path

meta_path, artifact, freq, rate, gain = sys.argv[1:6]
data = json.loads(Path(meta_path).read_text())
rf = data.setdefault("rf", {})
rf["frequency_hz"] = int(freq)
rf["sample_rate_hz"] = int(rate)
rf["gain"] = float(gain) if "." in gain else int(gain)
arts = data.setdefault("artifacts", {})
raw = arts.setdefault("raw", [])
rel = f"raw/{artifact}"
if rel not in raw:
    raw.append(rel)
Path(meta_path).write_text(json.dumps(data, indent=2) + "\n")
print(f"Updated {meta_path} artifacts.raw += {rel}")
PY
fi

echo "Done. Note what you did during the capture in ${SESSION_DIR}/notes.md"
