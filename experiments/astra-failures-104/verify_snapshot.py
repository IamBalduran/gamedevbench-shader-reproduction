import csv, hashlib, json
from pathlib import Path
p=Path(__file__).resolve().parent
rows=list(csv.DictReader((p/'results/comparison_portable.csv').open(encoding='utf-8-sig')))
assert len(rows)==416
done=[r for r in rows if r['state']=='completed']
assert len(done)==380
for r in done:
 for k in ['artifact_dir','trajectory_log','result_json','solver_result_json','console_log']:
  assert (p/r[k]).exists(),(r['model'],r['task'],k)
assert len(list((p/'gamedevbench-main/gamedevbench-main/tasks').glob('task_*.zip')))==104
manifest=json.loads((p/'results/snapshot_hashes.json').read_text(encoding='utf8'))
for name,digest in manifest.items():
 assert hashlib.sha256((p/name).read_bytes()).hexdigest()==digest,name
print(f'OK: 104 tasks, 416 cases, 380 completed; {len(manifest)} file hashes verified; no API calls.')
