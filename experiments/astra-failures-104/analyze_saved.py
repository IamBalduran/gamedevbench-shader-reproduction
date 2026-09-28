import json, csv, re
from pathlib import Path
from zipfile import ZipFile
from collections import Counter
ROOT=Path(__file__).parent
ENV=ROOT/'gamedevbench-environment'
REPO=ROOT/'gamedevbench-main/gamedevbench-main'
OUT=ROOT/'analysis'
OUT.mkdir(exist_ok=True)
MODELS=['gpt6_astra','gpt56_sol','deepseek_v4_pro','kimi_k3']
def local(p): return Path('D:/'+p[7:]) if p.startswith('/mnt/d/') else Path(p)
states={m:json.loads((ENV/f'batch_runs/{m}_official_failures_104/state.json').read_text(encoding='utf-8')) for m in MODELS}
tasks=[]
for t in states[MODELS[0]]['tasks']:
    with ZipFile(REPO/f'tasks/{t}.zip') as z:
        cfg=json.loads(z.read(f'tasks/{t}/task_config.json'))
        val=z.read(f'tasks/{t}/scripts/test.gd').decode('utf-8')
    (OUT/f'{t}_validator.gd').write_text(val,encoding='utf-8')
    tasks.append({'task':t,'instruction':cfg.get('instruction',''),'validator':val})
(OUT/'task_inventory.json').write_text(json.dumps(tasks,ensure_ascii=False,indent=2),encoding='utf-8')
rows=[]
for m,s in states.items():
 for t,i in s['items'].items():
    row={'model':m,'task':t,**i}
    if i['state']=='completed':
      p=local(i['trajectory_log']); text=p.read_text(encoding='utf-8',errors='replace')
      events=[]
      for line in text.splitlines():
       try:
        e=json.loads(line)
        if isinstance(e,dict):events.append(e)
       except ValueError:pass
      row['trajectory_event_counts']=dict(Counter(e.get('type','') for e in events))
      row['trajectory_errors']=[e.get('error',{}) for e in events if e.get('type')=='error']
      row['tool_names']=dict(Counter(e.get('part',{}).get('tool','') for e in events if e.get('type')=='tool_use'))
      row['trajectory_tail']=text[-1500:]
    rows.append(row)
(OUT/'case_metrics.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
for t in tasks:
 print(t['task'],t['instruction'][:700].replace('\n',' '))
print('\nSOLVER FAILURES')
for m in MODELS:
 rs=[r for r in rows if r['model']==m and r['state']=='completed']
 print(m,Counter(r['solver_message'].split('\n')[0] for r in rs if not r.get('solver_success')))
