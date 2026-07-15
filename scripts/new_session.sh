#!/usr/bin/env bash
# Create sessions/YYYY-MM-DD_<slug>/ with metadata templates.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="${1:-}"
SCENARIO="${2:-}"

if [[ -z "${SLUG}" ]]; then
  echo "Usage: $0 <slug> [scenario description]"
  echo "Example: $0 first-listen 'Idle near CTR300TT2 + HomeVision Pro'"
  exit 1
fi

if [[ ! "${SLUG}" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Slug must match [a-z0-9][a-z0-9-]* (got: ${SLUG})"
  exit 1
fi

DAY="$(date +%Y-%m-%d)"
SESSION_ID="${DAY}_${SLUG}"
DIR="${ROOT}/sessions/${SESSION_ID}"

if [[ -e "${DIR}" ]]; then
  echo "Session already exists: ${DIR}"
  exit 1
fi

mkdir -p "${DIR}/raw" "${DIR}/annotated" "${DIR}/replay"
: > "${DIR}/raw/.gitkeep"

STARTED_AT="$(date --iso-8601=seconds)"
TEMPLATE="${ROOT}/templates/session.json"

python3 - "${TEMPLATE}" "${DIR}/session.json" "${SESSION_ID}" "${STARTED_AT}" "${SCENARIO}" <<'PY'
import json, sys
from pathlib import Path

template_path, out_path, session_id, started_at, scenario = sys.argv[1:6]
data = json.loads(Path(template_path).read_text())
data["session_id"] = session_id
data["started_at"] = started_at
data["scenario"] = scenario
data["rf"]["frequency_hz"] = 868000000
data["rf"]["sample_rate_hz"] = 2048000
data["rf"]["tooling"] = ["rtl-sdr-blog-v4"]
Path(out_path).write_text(json.dumps(data, indent=2) + "\n")
PY

cat > "${DIR}/notes.md" <<EOF
# ${SESSION_ID}

## Goal

${SCENARIO:-_TBD_}

## Procedure

1. \`./scripts/check_rtlsdr.sh\`
2. Optional: open GQRX at 868 MHz, confirm activity
3. \`./scripts/capture_iq.sh sessions/${SESSION_ID} --duration 10 --label <name>\`
4. Operate HomeVision / CTR300 intentionally; note wall-clock times here

## Observations

-

## Follow-ups

-
EOF

echo "Created ${DIR}"
echo "  session.json  notes.md  raw/  annotated/  replay/"
echo
echo "Next:"
echo "  ./scripts/capture_iq.sh sessions/${SESSION_ID} --duration 10 --label idle"
