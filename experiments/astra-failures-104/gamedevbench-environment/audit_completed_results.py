"""Offline integrity check and compact four-model result summary."""
from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
PROJECT = BASE.parent
BATCHES = BASE / "batch_runs"
MODEL_IDS = ("gpt6_astra", "gpt56_sol", "deepseek_v4_pro", "kimi_k3")


def as_local(value: str) -> Path:
    if value.startswith("/mnt/d/"):
        return Path("D:/" + value[7:])
    return Path(value)


def main() -> None:
    report = {"checked_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
              "expected_cases": 416, "models": [], "missing_or_mismatched": []}
    for model in MODEL_IDS:
        batch = BATCHES / f"{model}_official_failures_104"
        state = json.loads((batch / "state.json").read_text(encoding="utf-8"))
        counts = Counter(item["state"] for item in state["items"].values())
        classifications = Counter(item.get("classification", "") for item in state["items"].values()
                                  if item["state"] == "completed")
        passes = 0
        cost = 0.0
        for task, item in state["items"].items():
            if item["state"] != "completed":
                continue
            passes += item.get("official_success") is True
            cost += float(item.get("cost_usd") or 0)
            for name in ("solver_result_json", "trajectory_log", "console_log", "artifact_dir"):
                value = item.get(name)
                if not value or not as_local(value).exists():
                    report["missing_or_mismatched"].append({"model": model, "task": task, "field": name})
            if item.get("validation_source") != "solver_artifact_validation":
                value = item.get("result_json")
                if not value or not as_local(value).is_file():
                    report["missing_or_mismatched"].append({"model": model, "task": task, "field": "result_json"})
            source = item.get("solver_result_json")
            if source and as_local(source).is_file():
                saved = json.loads(as_local(source).read_text(encoding="utf-8"))
                if saved.get("task_name") != task or saved.get("validation", {}).get("message") != item.get("official_message"):
                    report["missing_or_mismatched"].append({"model": model, "task": task, "field": "source_consistency"})
            if not item.get("official_message"):
                report["missing_or_mismatched"].append({"model": model, "task": task, "field": "official_message"})
        report["models"].append({"model": state["config"]["model"], "counts": dict(counts),
                                 "completed": counts["completed"], "official_passes": passes,
                                 "classifications": dict(classifications), "completed_cost_usd": round(cost, 6)})
    report["total_completed"] = sum(row["completed"] for row in report["models"])
    report["integrity_issue_count"] = len(report["missing_or_mismatched"])
    path = BATCHES / "official_failures_comparison" / "artifact_integrity.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"total_completed": report["total_completed"], "integrity_issue_count": report["integrity_issue_count"]},
                     ensure_ascii=False))


if __name__ == "__main__":
    main()
