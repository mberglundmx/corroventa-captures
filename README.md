# corroventa-captures

RF captures, session metadata, and helper scripts for reverse engineering the Corroventa wireless protocol.

**Hardware focus (initial):** RTL-SDR Blog V4 @ **868 MHz** (receive-only).

This repository may contain capture/conversion scripts under `scripts/`.
It must **not** contain the protocol library, MQTT gateway, or production firmware.
See `corroventa-engineering` ADR-0008.

## Layout

```
sessions/
  YYYY-MM-DD_<slug>/
    session.json      # required metadata
    notes.md          # human notes
    raw/              # immutable recorder output (IQ, etc.)
    annotated/        # interpretations
    replay/           # stable fixtures for protocol tests (later)
scripts/
  check_rtlsdr.sh
  new_session.sh
  capture_iq.sh
templates/
  session.json
```

Raw files under `sessions/**/raw/` are gitignored by default (IQ dumps grow fast).
Commit `session.json`, `notes.md`, and small annotated/replay artefacts.
Force-add or use Git LFS when a raw capture must be archived in git.

## Quick start (when the stick is plugged in)

```bash
# 1. Driver / device smoke test
./scripts/check_rtlsdr.sh

# 2. Create a session folder + metadata
./scripts/new_session.sh first-listen "CTR300TT2 + HomeVision Pro idle listen"

# 3. Capture IQ centred on 868 MHz (defaults; override as needed)
./scripts/capture_iq.sh sessions/$(ls -1t sessions | head -1) --duration 10 --label idle
```

Open **GQRX**, tune to `868000000` Hz, confirm bursts while operating the devices, then capture with the script (or save from GQRX into `raw/`).

## Defaults

| Setting | Default |
|---------|---------|
| Frequency | 868_000_000 Hz |
| Sample rate | 2_048_000 Hz |
| Gain | 0 (auto / tuner default via `rtl_sdr -g 0`) |

Record the actual gain and antenna in `session.json` / `notes.md`.

## Related docs

- `corroventa-engineering/REVERSE_ENGINEERING.md`
- `corroventa-engineering/experiments/0001-find-frequency.md`
