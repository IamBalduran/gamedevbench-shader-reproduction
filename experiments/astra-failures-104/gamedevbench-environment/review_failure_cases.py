"""Post-score Astra review. Never expose validator or baseline to the solver."""
from __future__ import annotations

import argparse
import csv
import difflib
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
from zipfile import ZipFile

import httpx

from run_official_failures_comparison import BASE, REPO, ROOT, COMPARISON, models, selected_tasks

OUT = COMPARISON / "astra_review"
TEXT_EXT = {".gd", ".tscn", ".tres", ".gdshader", ".shader", ".json", ".cfg", ".godot", ".md"}
REVIEW_FIELDS = ["task", "model", "run_name", "review_state", "official_success", "solver_success",
                 "official_message", "author_astra_message", "root_cause", "validator_method",
                 "false_negative_assessment", "standards_issue", "evidence", "countertest",
                 "confidence", "limitations", "review_json", "evidence_json", "review_error"]


def atomic(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def changed_text(task: str, output: Path) -> tuple[str, list[str]]:
    archive = REPO / "tasks" / f"{task}.zip"
    excerpts = []
    changed = []
    with ZipFile(archive) as zipped:
        prefix = f"tasks/{task}/"
        original = {name[len(prefix):]: name for name in zipped.namelist() if name.startswith(prefix)}
        for file in sorted(output.rglob("*")):
            if not file.is_file() or file.suffix.lower() not in TEXT_EXT or ".godot" in file.parts:
                continue
            rel = file.relative_to(output).as_posix()
            if rel in {"task_config.json", "scripts/test.gd", "result.json"}:
                continue
            try:
                new = file.read_text(encoding="utf-8")
                old = zipped.read(original[rel]).decode("utf-8") if rel in original else ""
            except (UnicodeError, KeyError, OSError):
                continue
            if new == old:
                continue
            changed.append(rel)
            diff = "".join(difflib.unified_diff(old.splitlines(keepends=True), new.splitlines(keepends=True),
                                                fromfile=f"original/{rel}", tofile=f"solver/{rel}"))
            excerpts.append(diff)
    content = "\n".join(excerpts)
    return content[:100_000], changed


def baseline_messages() -> dict[str, str]:
    baseline = json.loads((REPO / "results/gpt6_astra_codex_runtime_video_high_full_333/final_results.json").read_text(encoding="utf-8"))
    selected = set(selected_tasks())
    return {row["task_name"]: row["message"] for row in baseline["tasks"] if row["task_name"] in selected}


def evidence_for(task: str, model: dict, item: dict, author_message: str) -> dict:
    run_name = item.get("run_name", "")
    output = Path(item.get("artifact_dir", "")) if item.get("artifact_dir") else None
    if output and output.is_dir():
        diff, changed = changed_text(task, output)
    else:
        diff, changed = "", []
    with ZipFile(REPO / "tasks" / f"{task}.zip") as zipped:
        root = f"tasks/{task}/"
        config = json.loads(zipped.read(root + "task_config.json"))
        validator = zipped.read(root + "scripts/test.gd").decode("utf-8")
    trajectory = Path(item.get("trajectory_log", "")) if item.get("trajectory_log") else None
    trajectory_excerpt = ""
    if trajectory and trajectory.is_file():
        raw = trajectory.read_text(encoding="utf-8", errors="replace")
        trajectory_excerpt = raw[-24_000:]
    return {
        "task": task, "model": model["opencode_id"], "run_name": run_name,
        "task_instruction": config.get("instruction", ""),
        "author_astra_first_failure": author_message,
        "local_official_success": item.get("official_success"),
        "local_official_message": item.get("official_message", ""),
        "local_official_details": item.get("official_details", ""),
        "local_solver_success": item.get("solver_success"),
        "local_solver_message": item.get("solver_message", ""),
        "validator_source": validator,
        "validator_error_line": item.get("validator_error_line", ""),
        "changed_files": changed,
        "solver_diff": diff,
        "solver_diff_truncated": len(diff) >= 100_000,
        "trajectory_tail": trajectory_excerpt,
        "trajectory_excerpt_only": bool(trajectory_excerpt),
        "full_trajectory_path": str(trajectory) if trajectory else "",
        "artifact_dir": str(output) if output else "",
        "published_author_output_available": False,
        "note": "The author's Astra output artifact is absent; do not claim a confirmed false negative for that run."
    }


def prompt_for(evidence: dict) -> str:
    return (
        "You are auditing a GameDevBench result AFTER the coding agent has finished and the official validator has run. "
        "This is a separate post-hoc analysis; do not propose code edits. Use only supplied evidence. "
        "Distinguish solver failure, genuine task failure, possible validator false negative, and evidence insufficient. "
        "A model's claim that its own work succeeded is not proof. The published Astra run's output artifact is unavailable, "
        "so never call the published result a confirmed false negative. Examine the exact validator method and whether it "
        "tests the requested behavior or an overly specific implementation. Identify a concrete countertest where needed. "
        "Return ONLY a JSON object with keys: root_cause, validator_method, false_negative_assessment "
        "(one of no_evidence, possible, strong_evidence, not_applicable), standards_issue "
        "(one of none_found, possible_overconstraint, weak_behavioral_coverage, environment_mismatch, unclear), "
        "evidence (array of concise source-based observations), countertest, confidence (low/medium/high), limitations. "
        "Write concise Chinese.\n\nEvidence:\n" + json.dumps(evidence, ensure_ascii=False)
    )


def extract_text(response: dict) -> str:
    pieces = []
    for output in response.get("output", []):
        if output.get("type") != "message":
            continue
        for part in output.get("content", []):
            if part.get("type") in ("output_text", "text"):
                pieces.append(part.get("text", ""))
    return "\n".join(pieces)


def review_one(client: httpx.Client, task: str, model: dict, item: dict, author_message: str) -> dict:
    case_dir = OUT / model["key"] / task
    case_dir.mkdir(parents=True, exist_ok=True)
    evidence = evidence_for(task, model, item, author_message)
    evidence_path = case_dir / "evidence.json"
    atomic(evidence_path, evidence)
    prompt = prompt_for(evidence)
    prompt_path = case_dir / "review_request.json"
    atomic(prompt_path, {"model": "gpt-6-astra", "prompt": prompt, "store": False})
    last_error = ""
    for attempt in range(1, 4):
        try:
            response = client.post("https://api.shubiaobiao.cn/v1/responses", json={
                "model": "gpt-6-astra", "store": False,
                "reasoning": {"effort": "medium"},
                "input": [{"role": "user", "content": prompt}],
            })
            raw_path = case_dir / f"astra_response_attempt_{attempt}.json"
            raw_path.write_text(response.text, encoding="utf-8")
            response.raise_for_status()
            raw = response.json()
            output_text = extract_text(raw).strip()
            match = re.search(r"\{.*\}", output_text, re.DOTALL)
            if not match:
                raise ValueError("Astra returned no JSON object")
            assessment = json.loads(match.group(0))
            required = {"root_cause", "validator_method", "false_negative_assessment", "standards_issue",
                        "evidence", "countertest", "confidence", "limitations"}
            if not isinstance(assessment, dict) or not required.issubset(assessment):
                raise ValueError("Astra review JSON missing required fields")
            record = {"review_state": "completed", "reviewer_model": "gpt-6-astra", "review_attempts": attempt,
                      "researcher_verified": False, "assessment": assessment,
                      "request_sha256": hashlib.sha256(prompt.encode()).hexdigest(),
                      "evidence_json": str(evidence_path), "review_request_json": str(prompt_path),
                      "raw_response_json": str(raw_path), "review_error": ""}
            atomic(case_dir / "review.json", record)
            return record
        except (httpx.HTTPError, ValueError, json.JSONDecodeError) as exc:
            last_error = f"{type(exc).__name__}: {exc}"
            if attempt < 3:
                time.sleep(10 * attempt)
    record = {"review_state": "error", "reviewer_model": "gpt-6-astra", "review_attempts": 3,
              "researcher_verified": False, "assessment": {}, "evidence_json": str(evidence_path),
              "review_request_json": str(prompt_path), "review_error": last_error}
    atomic(case_dir / "review.json", record)
    return record


def save_index(selected: list[dict], messages: dict[str, str]) -> list[dict]:
    rows = []
    for model in selected:
        path = ROOT / model["batch_id"] / "state.json"
        state = json.loads(path.read_text(encoding="utf-8"))
        for task in state["tasks"]:
            item = state["items"][task]
            review_path = OUT / model["key"] / task / "review.json"
            review = json.loads(review_path.read_text(encoding="utf-8")) if review_path.is_file() else {}
            assessment = review.get("assessment", {})
            rows.append({
                "task": task, "model": model["opencode_id"], "run_name": item.get("run_name", ""),
                "review_state": review.get("review_state", "pending" if item["state"] == "completed" else item["state"]),
                "official_success": item.get("official_success", ""), "solver_success": item.get("solver_success", ""),
                "official_message": item.get("official_message", ""),
                "author_astra_message": messages[task],
                "root_cause": assessment.get("root_cause", ""),
                "validator_method": assessment.get("validator_method", ""),
                "false_negative_assessment": assessment.get("false_negative_assessment", ""),
                "standards_issue": assessment.get("standards_issue", ""),
                "evidence": json.dumps(assessment.get("evidence", []), ensure_ascii=False),
                "countertest": assessment.get("countertest", ""),
                "confidence": assessment.get("confidence", ""),
                "limitations": assessment.get("limitations", ""),
                "review_json": str(review_path) if review else "",
                "evidence_json": review.get("evidence_json", ""),
                "review_error": review.get("review_error", ""),
            })
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "astra_assessments.csv"
    tmp = path.with_suffix(".csv.tmp")
    with tmp.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tmp, path)
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-tasks", type=int, default=0, help="0 reviews all currently completed, unreviewed cases")
    parser.add_argument("--index-only", action="store_true")
    parser.add_argument("--prepare-evidence-only", action="store_true",
                        help="Create local review evidence without any API request")
    args = parser.parse_args()
    _, selected = models()
    messages = baseline_messages()
    rows = save_index(selected, messages)
    if args.index_only:
        print(f"Astra review index initialized: {len(rows)} cases, no model call")
        return 0
    if args.prepare_evidence_only:
        prepared = 0
        for model in selected:
            state = json.loads((ROOT / model["batch_id"] / "state.json").read_text(encoding="utf-8"))
            for task in state["tasks"]:
                item = state["items"][task]
                if item["state"] != "completed":
                    continue
                path = OUT / model["key"] / task / "evidence.json"
                if not path.is_file():
                    atomic(path, evidence_for(task, model, item, messages[task]))
                    prepared += 1
                    print(f"Local evidence prepared: {model['opencode_id']} {task}", flush=True)
        print(f"Local evidence files created: {prepared}; no model API call", flush=True)
        return 0
    if os.environ.get("GAMEDEVBENCH_REVIEW_EXPORT_APPROVED") != "1":
        raise SystemExit("Astra external review is disabled pending explicit approval of the review payload export")
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        raise SystemExit("No local API key; review did not call Astra")
    done = 0
    with httpx.Client(headers={"Authorization": f"Bearer {key}"}, timeout=600) as client:
        for model in selected:
            state = json.loads((ROOT / model["batch_id"] / "state.json").read_text(encoding="utf-8"))
            for task in state["tasks"]:
                item = state["items"][task]
                if item["state"] != "completed":
                    continue
                review_path = OUT / model["key"] / task / "review.json"
                if review_path.is_file():
                    record = json.loads(review_path.read_text(encoding="utf-8"))
                    if record.get("review_state") == "completed":
                        continue
                if args.max_tasks and done >= args.max_tasks:
                    save_index(selected, messages)
                    return 0
                print(f"Astra post-score review {done + 1}: {model['opencode_id']} {task}", flush=True)
                review_one(client, task, model, item, messages[task])
                done += 1
                save_index(selected, messages)
    print(f"Astra review saved: {done} new cases, {len(rows)} indexed", flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("Astra review stopped; completed review JSON files remain saved", flush=True)
        sys.exit(130)
