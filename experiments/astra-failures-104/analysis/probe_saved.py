import json, shutil, subprocess, re, sys
from pathlib import Path
P=Path(__file__).resolve().parent
ROOT=P.parent
GODOT=ROOT/'gamedevbench-environment/tools/Godot_v4.4.1-stable_linux.x86_64'
rows=json.loads((P/'case_metrics.json').read_text())
out=[]
for r in rows:
 if r['state']!='completed' or r['task'] not in ['task_0093','task_0150','task_0107','task_0028']:continue
 if len(sys.argv)>1 and r['task']!=sys.argv[1]:continue
 src=Path(r['artifact_dir']); dst=P/'probes'/(r['model']+'_'+r['task'])
 if not dst.exists():shutil.copytree(src,dst)
 original=(P/(r['task']+'_validator.gd')).read_text()
 if r['task']=='task_0107':
  modified=original.replace('var surface_material = mesh.surface_get_material(0)','var surface_material = mesh_instance.get_active_material(0)')
 elif r['task']=='task_0028':modified=original.replace('"PillarPoint"','"FlashlightPoint"').replace('"GatePoint"','"FlashlightPoint2"').replace('"EnemyPoint"','"FlashlightPoint3"')
 else:modified=original.replace('size_flags_horizontal != 4','size_flags_horizontal != Control.SIZE_EXPAND_FILL')
 (dst/'scripts/test.gd').write_text(modified)
 try:
  p=subprocess.run([str(GODOT),'--headless','--path',str(dst),'res://scenes/test.tscn'],capture_output=True,text=True,timeout=40)
  log=p.stdout+'\n'+p.stderr;code=p.returncode
 except subprocess.TimeoutExpired as e:log=str(e.stdout)+'\n'+str(e.stderr);code='timeout'
 (dst/'audit_probe.log').write_text(log)
 result={'model':r['model'],'task':r['task'],'original_message':r['official_message'],'solver_success':r['solver_success'],'modified_exit':code,'messages':re.findall(r'VALIDATION_(?:PASSED|FAILED):[^\n]*',log),'log':str(dst/'audit_probe.log')}
 out.append(result);print(json.dumps(result),flush=True)
 (P/('probe_results_'+sys.argv[1]+'.json' if len(sys.argv)>1 else 'probe_results.json')).write_text(json.dumps(out,indent=2))
