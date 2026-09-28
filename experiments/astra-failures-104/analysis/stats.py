import json,re,csv
from collections import Counter
from pathlib import Path
P=Path(__file__).parent
tasks=json.loads((P/'task_inventory.json').read_text(encoding='utf-8'))
rows=json.loads((P/'case_metrics.json').read_text(encoding='utf-8'))
models=['gpt6_astra','gpt56_sol','deepseek_v4_pro','kimi_k3']
def category(t):
 n=int(t[-4:])
 if 204<=n<=215:return '视觉定位：陷阱生成点'
 if 216<=n<=226:return '视觉定位：金币轮廓'
 if 227<=n<=237:return '视觉定位：星星轮廓'
 if 238<=n<=248:return '视觉定位：宝石轮廓'
 if 263<=n<=273:return 'AI感知与目标选择'
 if 281<=n<=291:return '卡牌拖拽状态机'
 if 69<=n<=78:return '3D水面与相机构图'
 if n in [19,30,33,95,107]:return '粒子、材质与Shader'
 if n in [3,82,87]:return '精灵动画与碰撞体'
 if n in [58,63,89,93,121,150,159]:return 'UI、对话与音频面板'
 if n in [108,183,185,190]:return 'TileSet地图数据'
 if n in [26,27,28,34,42,60,132]:return '摄像机、场景接线与小地图'
 return '角色运动、战斗与交互'
for t in tasks:t['category']=category(t['task'])
rs=[r for r in rows if r['state']=='completed']
common={r['task'] for r in rs if r['model']=='kimi_k3'}
print('OVERALL')
for m in models:
 a=[r for r in rs if r['model']==m]; b=[r for r in a if r['task'] in common]
 print(m,len(a),'pass',sum(r['official_success'] for r in a),'solver',sum(r['solver_success'] for r in a),'joint',sum(r['official_success'] and r['solver_success'] for r in a),'timeout',sum('timed out after 600s' in r['solver_message'] for r in a),'common',len(b),sum(r['official_success'] for r in b),'errors',Counter(str(e.get('name')) for r in a for e in r.get('trajectory_errors',[])))
print('CATEGORIES')
for c in dict.fromkeys(t['category'] for t in tasks):
 ids={t['task'] for t in tasks if t['category']==c}
 print(c,len(ids),[(m,len(a:=[r for r in rs if r['model']==m and r['task'] in ids]),sum(r['official_success'] for r in a),sum(r['solver_success'] for r in a)) for m in models])
print('NORMAL SOLVER FIRST FAILURE')
print(Counter(r['official_message'] for r in rs if r['solver_success'] and not r['official_success']).most_common(20))
print('VALIDATOR PATTERNS')
patterns={'源码字符串检查':r'\.contains\(|\.find\(|\.findn\(', '多边形IoU':r'func polygon_iou', '动态等待':r'await ', '近似/容差':r'is_equal_approx|distance_to\(|abs\(', '运行函数调用':r'\.call\(|\.show_screen\(|\._input\(|\._physics_process\('}
for k,p in patterns.items():print(k,len([t for t in tasks if re.search(p,t['validator'])]))
(P/'categorized_tasks.json').write_text(json.dumps(tasks,ensure_ascii=False,indent=2),encoding='utf-8')
with (P/'case_table.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['model','task','category','state','official_success','solver_success','official_message','solver_message','artifact_dir','trajectory_log']);w.writeheader()
 for r in rows:w.writerow({k:category(r['task']) if k=='category' else r.get(k,'') for k in w.fieldnames})
