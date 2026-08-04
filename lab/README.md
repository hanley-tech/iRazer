# lab/ — reverse-engineering data

Inputs (candidate definitions) and outputs (result logs) for the fuzzers and the
app's Lab tab. Safe to delete result `*.jsonl` files to start a run fresh; the
fuzzers append and skip already-tested IDs where supported.

## Inputs

- `experiments.json` — batches for the app's **Lab** tab. Array of
  `{id, title, detail, packets:[{tx, bytes}]}`. `bytes` = `"cls id size args…"` hex.
- `fuzz-candidates.json` — USB packets for `nommofuzz run`. `{id, tx, packets:[hex…]}`.
- `ble-framings.json` — BLE framings for `nommoblefuzz`. `{id, template}` where the
  template contains `RR GG BB` placeholders swapped for red/green during the run.

## Outputs

- `results.jsonl` — app Lab tab verdicts (one JSON object per experiment).
- `results-batch1.jsonl` — archived first Lab batch.
- `fuzz-results.jsonl` — `nommofuzz` USB run: per candidate, pre/post hue+brightness
  and a verdict (`no-change` / `hit-*`). Resumable (skips logged IDs).
- `ble-fuzz-results.jsonl` — `nommoblefuzz` BLE run: red/green hue, saturation, diff,
  verdict (`COLOR-MATCH` / `changed` / `no-change`) and any notify bytes.
- `console.jsonl` — everything sent/received from the app's **Console** tab.

## How to read a fuzz verdict

Camera classification is a **before/after comparison** (the idle spectrum cycle drifts
slowly, so absolute color means little). A candidate is interesting only if it makes an
instant **hue jump >30°** or a **brightness blackout** — and, for BLE, only
`COLOR-MATCH` (observed color follows commanded red→green) is trustworthy. A run where
the camera wasn't aimed at the glow produces constant-hue rows and must be discarded.

See `../docs/FINDINGS.md` for the current protocol map and what each result established.
