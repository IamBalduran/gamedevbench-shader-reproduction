"""Check that every portable comparison row resolves to saved evidence."""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BENCH = ROOT / "gamedevbench-main" / "gamedevbench-main"
TABLE = ROOT / "results" / "comparison_portable.csv"


def fail(message: str) -> None:
    raise AssertionError(message)


def main() -> None:
    manifest = json.loads((ROOT / "results" / "manifest.json").read_text(encoding="utf-8"))
    with TABLE.open(encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    tasks = manifest["task_ids"]
    models = manifest["model_batch_ids"]
    if len(rows) != len(tasks) * len(models) or len(rows) != manifest["records"]:
        fail("record count mismatch")
    seen = set()
    for task in tasks:
        archive = BENCH / "tasks" / f"{task}.zip"
        if not archive.is_file() or not zipfile.is_zipfile(archive):
            fail(f"missing/invalid task ZIP: {task}")
        if not (BENCH / "tasks" / task / "scripts" / "test.gd").is_file():
            fail(f"missing validator: {task}")
    for row in rows:
        pair = (row["batch_id"], row["task"])
        if pair in seen:
            fail(f"duplicate run: {pair}")
        seen.add(pair)
        if pair[0] not in models or pair[1] not in tasks:
            fail(f"unexpected run: {pair}")
        for field in ("result_json", "solver_result_json", "artifact_dir", "trajectory_log", "console_log"):
            value = row[field]
            if not value:
                continue
            relative = Path(value)
            if relative.is_absolute() or ".." in relative.parts:
                fail(f"nonportable path in {pair}: {field}")
            path = ROOT / relative
            if not path.exists():
                fail(f"missing {field} for {pair}: {value}")
        official = json.loads((ROOT / row["result_json"]).read_text(encoding="utf-8"))
        if str(official.get("success", "")).lower() != row["official_success"].lower():
            fail(f"official verdict mismatch: {pair}")
    for batch in models:
        state = ROOT / "gamedevbench-environment" / "batch_runs" / batch / "state.json"
        if not state.is_file():
            fail(f"missing checkpoint: {batch}")
    baseline = ROOT / manifest["official_baseline"]
    if not baseline.is_file():
        fail("missing published Astra baseline")
    hashes = ROOT / "results" / "file_hashes.sha256"
    checked = 0
    with hashes.open(encoding="utf-8") as handle:
        for line in handle:
            expected, relative = line.rstrip("\n").split("  ", 1)
            path = ROOT / relative
            if not path.is_file():
                fail(f"missing hashed file: {relative}")
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest != expected:
                fail(f"file hash mismatch: {relative}")
            checked += 1
    digest = hashlib.sha256(TABLE.read_bytes()).hexdigest()
    print(f"OK: {len(tasks)} tasks, {len(models)} models, {len(rows)} records, {checked} hashed files; comparison SHA-256 {digest}")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, ValueError, KeyError) as exc:
        print(f"Package check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
