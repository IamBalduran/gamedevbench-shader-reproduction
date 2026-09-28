"""Record immutable input/tool hashes and the copied pilot's provenance."""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
from datetime import datetime, timezone

BASE = Path(__file__).resolve().parent
ROOT = BASE.parent
REPO = ROOT / "gamedevbench-main/gamedevbench-main"


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def main() -> None:
    with (BASE / "audit/official_failures.csv").open(encoding="utf-8-sig", newline="") as handle:
        tasks = [row["task_name"] for row in csv.DictReader(handle)]
    fixed = {
        "published_astra_baseline": REPO / "results/gpt6_astra_codex_runtime_video_high_full_333/final_results.json",
        "selection": BASE / "audit/official_failures.csv",
        "godot": BASE / "tools/Godot_v4.4.1-stable_linux.x86_64",
        "uv_lock": REPO / "uv.lock",
        "benchmark_runner": REPO / "gamedevbench/src/benchmark_runner.py",
        "opencode_config": REPO / "opencode.json",
        "provider_plugin": REPO / "gamedevbench/shubiaobiao_plugin.mjs",
        "runner": BASE / "run_batch.py",
        "orchestrator": BASE / "run_official_failures_comparison.py",
    }
    hashes = {key: {"path": str(path.relative_to(ROOT)), "sha256": digest(path)} for key, path in fixed.items()}
    archives = {task: digest(REPO / "tasks" / f"{task}.zip") for task in tasks}
    old_batch_path = Path(r"D:\ShaderAgent\re\gamedevbench-environment\batch_runs\gpt6_astra_official_failures_104\state.json")
    batch = json.loads(old_batch_path.read_text(encoding="utf-8"))
    imported = []
    for task, item in batch["items"].items():
        if item.get("run_name") and item.get("attempts", 0):
            imported.append({"task": task, "state_at_import": item.get("state"),
                             "run_name": item["run_name"], "original_directory":
                             "D:/ShaderAgent/re/gamedevbench-main/gamedevbench-main"})
    manifest = {"created_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "selection_count": len(tasks), "expected_solver_cases": 416,
                "copied_from": "D:/ShaderAgent/re/gamedevbench-main/gamedevbench-main",
                "input_hashes": hashes, "archive_sha256": archives,
                "imported_pre_isolation_attempts": imported,
                "secret_in_manifest": False}
    path = ROOT / "experiment_manifest.json"
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(path)


if __name__ == "__main__":
    main()
