import json,csv,re
from pathlib import Path
from collections import Counter
P=Path(__file__).resolve().parent; OUT=P.parent/'results';OUT.mkdir(exist_ok=True)
rows=json.loads((P/'case_metrics.json').read_text(encoding='utf8'))
tasks=json.loads((P/'categorized_tasks.json').read_text(encoding='utf8'))
done=[r for r in rows if r['state']=='completed']
models=['gpt6_astra','gpt56_sol','deepseek_v4_pro','kimi_k3']
names=dict(zip(models,['GPT-6 Astra','GPT-5.6 Sol','DeepSeek V4 Pro','Kimi K3']))
probes=json.loads((P/'probe_results.json').read_text())+json.loads((P/'probe_results_task_0028.json').read_text())
confirmed={(r['model'],r['task']) for r in probes if any('VALIDATION_PASSED:' in s for s in r['messages'])}
assert len(done)==380 and len(confirmed)==12
def table(headers,rs):
 return '| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+''.join('| '+' | '.join(str(x).replace('|','/').replace('\n',' ') for x in row)+' |\n' for row in rs)
overview=[]
for m in models:
 a=[r for r in done if r['model']==m]; p=sum(r['official_success'] for r in a);s=sum(r['solver_success'] for r in a)
 overview.append([names[m],len(a),f'{p}/{len(a)} ({p/len(a):.1%})',s,sum('timed out after 600s' in r['solver_message'] for r in a),sum(r['official_success'] and r['solver_success'] for r in a)])
catrows=[]
for c in dict.fromkeys(t['category'] for t in tasks):
 ids={t['task'] for t in tasks if t['category']==c};cells=[]
 for m in models:
  a=[r for r in done if r['model']==m and r['task'] in ids]
  cells.append(f"{sum(r['official_success'] for r in a)}/{len(a)}；正常结束{sum(r['solver_success'] for r in a)}" if a else '未覆盖')
 catrows.append([c,len(ids),*cells])
first=Counter(r['official_message'] for r in done if r['solver_success'] and not r['official_success'])
common={r['task'] for r in done if r['model']=='kimi_k3'}
report1='''# 已有实验结果：模型薄弱板块与 Agent 改进方向

分析日期：2026-09-27。仅分析本机已保存数据，不调用外部模型，不恢复扣费实验。本文与《假阴性与 Rubric 改进》分开：本篇关注交付能力和执行过程，另篇核查评分规则。

## 1. 先明确这批数据能说明什么

计划为四模型 × 104 题，共 416 个案例。当前有 380 份完成记录：Astra、Sol、DeepSeek 各 104，Kimi 68；Kimi 剩余 36 题没有完成，不能按失败计分。额度中断不是模型能力失败。

104 题来自官方公布的 Astra 失败集合，是困难且有选择偏差的子集，不代表官方全部 333 题。题目还包含大量同模板变体，因此 380 个案例不是 380 个独立能力测试。下文分类是本次人工按任务目标划分，逐题映射已保存；不是作者的官方分类。

本次通过 Shubiaobiao 使用 OpenCode，配置为 high、runtime video、600 秒求解预算、代理步骤上限、并发 2、Godot 4.4.1，并保留官方验证器。官方历史 Astra 基线使用 Codex；代理框架、服务商链路等并非完全一致。不能把差距全部归因于基础模型，也不能由本次完成率反推官方原始失败原因。

统计区分三个量：

- **官方通过**：保存的官方 success 为真，保留原始口径。
- **求解器正常结束**：solver_success 为真，只表示运行器正常交接，不保证完成需求或实际测试通过。
- **双通过**：官方通过且求解器正常结束，用于观察执行与评分的交集，不能替代官方成绩。

## 2. 总体结果：主要瓶颈先是交付过程

'''+table(['模型','已完成记录','官方通过','求解器正常结束','600秒超时','双通过'],overview)+'''
合计官方通过 **35/380（9.2%）**，求解器正常结束 **193/380（50.8%）**，双通过 **28/380（7.4%）**。187 次求解器未正常完成，其中 **185 次超时**，另外两次是 Astra 的退出码 1 与 DeepSeek 的退出码 -4。7 个官方通过案例仍发生求解器未正常结束，说明“已经写出可评分产物”和“整个求解过程正常结束”是两回事。

在 193 次正常结束中，28 次官方通过、165 次未通过。后者仍同时混有真实实现缺陷、正常退出却没有交付完整产物、验证器误判，不能统称为能力失败。

四模型共同覆盖的前 68 题：Astra **7/68（10.3%）**，Sol **9/68（13.2%）**，DeepSeek **7/68（10.3%）**，Kimi **10/68（14.7%）**。这比直接比较 104 与 68 的比例更公平，但差距很小、样本偏置明显，也未做重复采样，不应宣布模型总体排名。

## 3. 哪些领域较差

下表“通过/完成；正常结束 N”同时展示评分与交付。未覆盖不是 0 分。

'''+table(['任务板块','题数','Astra','Sol','DeepSeek','Kimi'],catrows)+'''
### 3.1 视觉定位与轮廓标注：共同弱项，但失败层次不同

陷阱生成点共 **0/48** 通过，只有 **9/48** 正常结束。金币共 **0/44** 通过、29 次正常结束；星星共 **0/34** 通过、20 次正常结束。宝石共 **2/15** 通过，Kimi 尚未覆盖。

这组任务要求从图片识别目标，再把像素位置转换成 Godot 局部坐标，处理 Level 的平移、缩放和旋转，最后落地为节点或 Polygon2D。它同时考验观察、几何推算和资源写入。反复查看图片但没有尽早写入一个可检查的候选，是高风险执行方式。

具体证据：Astra task_0216 已生成金币轮廓，但最佳 IoU 为 **0.8399**，低于官方 0.90；task_0227 星星 IoU 为 **0.6225**，低于 0.85。这是“产物存在但几何不够贴合”的证据，不能仅凭主观截图认定假阴性。反过来，Kimi task_0216 缺少题目明确要求的 CoinHighlights，task_0227 缺少 StarHighlight，虽 solver_success 为真，仍没有交付必要对象；后者回复还出现达到最大步骤的说明。

原因判断：坐标转换/轮廓精度不足有直接证据；观察和规划消耗预算是轨迹支持的执行风险。不能仅由超时推断模型没有视觉能力，也不能排除代理的图像工具和返回延迟影响。

### 3.2 AI 感知与卡牌状态机：系统接线和时间预算叠加

AI 感知与目标选择 **0/30**，其中正常结束 10 次：Astra 9、Sol 1、DeepSeek 0；Kimi 未覆盖。卡牌拖拽状态机 **0/33**，仅 Astra 2 次正常结束，其余 31 次未正常结束。

这类任务涉及多个脚本、场景引用、碰撞层/分组、状态切换与事件顺序，单个函数正确不等于系统可用。Astra/Sol task_0263 在 base_range_size 必须为 30 的检查处失败，这是具体配置不一致；是否属于不合理隐含标准，需要再与完整任务要求逐条比对，本文不将它直接记为假阴性。

卡牌验证器会模拟按下、移动、释放、右键取消、目标重复进入/退出和提交后移除等过程，因此真正要求状态、父节点、序号和碰撞监控同步变化。当前大量超时使我们首先看到“在给定预算中交付不了系统”，而不是足够证据证明某模型的状态机逻辑先天较弱。

### 3.3 TileSet 与精灵碰撞：数据结构与引擎资源一致性薄弱

TileSet 地图数据 **0/16**，6 次正常结束；精灵动画与碰撞体 **0/12**，6 次正常结束。日志包括 TileSet 未定义 terrain set、Player 场景加载失败等具体问题。资源文件、场景实例、碰撞体和动画引用需要共同一致，纯文本修改未必能保证 Godot 正确导入或运行。

建议将这一结论限定为“本批少量任务上的资源交付薄弱”，不要从 3～4 个题型推出整个游戏开发领域的能力结论。

### 3.4 UI、场景接线、材质：原始低分受验证器影响明显

UI 板块原始 **4/28** 通过，但 23 次正常结束；场景接线等板块 **4/28**；粒子/材质/Shader **3/20**。这几组不能只按失败消息归因模型。

本次离线复测发现：两道 UI 的 Expand Fill 枚举值写错；FlashlightPoint 题要求了 prompt 没有规定的实例名；材质题只检查 Mesh 资源槽，忽略实际生效的覆盖材质。**12 个原始失败案例在不修改模型产物、只修正局部验证规则后，通过剩余原版检查**。详细名单与限制见第二篇。这些发现会实质改变我们对上述板块的判断。

### 3.5 相对较好的板块：3D 水面与相机构图

这一组官方 **20/36（55.6%）**：Astra 5/9，Sol 3/9，DeepSeek 4/9，Kimi 8/9。相较视觉标注和系统状态机明显更好。可能原因是目标场景和可调整参数集中、修改路径短，但这是机制假设，不是因果实验证明。9 题存在模板相似性，不能据此推断 Kimi 已全面掌握复杂三维任务。

## 4. 失败原因如何分层阅读

正常结束但官方未通过的 165 个案例中，最常见的首个失败点如下。验证器多为遇错即停，这些次数表示“首先阻挡通过的检查”，不是产物所有缺陷的总数。

'''+table(['原始首个失败消息','次数'],first.most_common(12))+'''
建议使用五层原因：①服务/运行器错误，②时间或步骤预算耗尽，③必要产物没有交付，④运行或行为不满足需求，⑤评分规则与任务目标不一致。⑤已确认的案例应从能力诊断中单列；②③不能因为进程返回 0 就忽略；④需要运行证据，不能依据模型最终回复中的“已验证”判断。

成本字段也应谨慎：当前最终案例记录合计约 Astra $12.49、Sol $3.03、DeepSeek $7.29、Kimi $66.99。这不是账单，不覆盖所有重试和基础设施开销，服务商计价映射也未经账单核实；不能用它直接给出性价比排名。

## 5. 可以做的 Agentic 改进：按证据选实验

'''+table(['改进方向','针对的现象','具体机制','如何验证改进'],[
['预算感知执行','185次600秒超时；正常退出也可能没交付','给观察、实现、检查设置阶段预算；先写最小可运行产物；接近步骤上限时优先保存并给出未完成清单','同时报告交付率、超时率、官方/审计通过率、工具调用数和耗时；固定总预算做消融'],
['需求清单与证据闭环','遗漏节点、属性和引用；自称验证但未达标准','从公开任务描述生成需求→文件/节点→检查证据清单；提交前逐项扫描资源并启动Godot','遗漏率和正常结束后的失败率；禁止把隐藏验证器提供给求解模型'],
['视觉坐标工具链','金币/星星轮廓偏差与陷阱定位失败','工具返回原图尺寸、局部裁剪、坐标轴与变换逆矩阵；保存候选轮廓叠图，逐步纠偏','相同图片工具预算下比较位置误差、IoU、写出有效Polygon2D的比例'],
['引擎资源自检','TileSet、场景加载、材质槽不一致','读取导入后的场景树和资源类型；检查实际材质、terrain数据、碰撞层与有效引用','导入错误数、运行时错误数、引用缺失率；同时保留有效等价实现'],
['事件驱动测试Agent','感知/卡牌跨节点接线','根据公开需求生成事件序列，记录状态、父子关系、信号、目标集合前后差异','状态转移覆盖率、取消/边界事件正确率；固定时间步避免测试抖动'],
['失败定位与有限修复','重复探索、没有利用运行证据','一次自测后按编译/资源/行为/几何分类，针对首个真实缺陷限次修复；保存每版diff','同预算单次生成vs闭环修复消融；记录修复收益及引入的新错误']])+'''
这些是待验证方案，不是本次已实现的提升。建议先在未用于设计改进的模板族上做小规模配对试验，按模板族划分训练/开发/测试，防止同图换坐标的变体泄漏；保持模型、预算和环境相同，只改变一个 Agent 机制。官方分数与审计分数同时报告，不用修改后的分数覆盖历史原始结果。

## 6. 数据和阅读入口

- [逐案例表（416行，包含未完成状态）](../analysis/case_table.csv)：官方错误、求解器状态、原始产物和轨迹路径。
- [完整指标快照](../analysis/case_metrics.json)、[104题分类与验证器](../analysis/categorized_tasks.json)。
- [逐题审计索引](逐题审计索引.csv)：每题四模型结果与审计标签。
- [假阴性与Rubric改进](02_假阴性与Rubric改进.md)：局部规则修正、离线复测、未确认案例及优化方案。

所有统计使用本次读取的案例状态和原始轨迹，不沿用早期缓存完整性报告中的计数。这里的“轨迹”是保存的可见回复与工具记录，不是模型隐藏思维链。没有重新调用模型，也没有更改原始官方结果。
'''
(OUT/'01_模型表现与Agent改进.md').write_text(report1,encoding='utf8')
probe_table=[]
for r in probes:
 probe_table.append([names[r['model']],r['task'],'是' if r['solver_success'] else '否', '；'.join(r['messages']) or '后续脚本类型错误，40秒终止',r['modified_exit']])
report2='''# 已有实验结果：假阴性与 Rubric 改进

分析日期：2026-09-27。离线审计，不向外部 API 发送任务、验证器或轨迹。原始官方成绩与产物全部保留；本篇记录审计结果，不覆写官方 success。

## 1. 核心结论与证据边界

**存在可以复现的验证器误拒绝。** 对 4 道题的 16 份模型产物做局部验证器修正复测，其中 **12 份**在不改模型代码或场景的情况下通过剩余原版检查：UI 7 份、实例命名 3 份、有效材质 2 份。覆盖四模型，11 份求解器正常结束，1 份求解超时但已写出可用产物。

这 12 份占原始 345 个未通过案例的 **3.5%**，占全部 380 个完成记录的 **3.2%**。这是本次已证实的“验证规则导致拒绝”的下界，不是假阴性的总体估计，也不意味着全部任务需求已获得穷尽验证。我们证明的是：失败来源可定位到不合理规则，修正规则后其余原版断言通过；仍未完成逐帧视觉质量、全部边界行为等独立验收。

另外发现词法检查、指定回调名、额外颜色要求等高风险规则，列为候选，不混入这 12 份。没有官方原始 Astra 产物，因此不能断言作者那 104 个历史失败中有多少假阴性。

## 2. 审计方法

1. 读取全部 104 题任务描述、官方 test.gd，逐项关联 380 份完成记录中的官方错误、solver状态和轨迹。保存题目/案例索引，未完成 36 份不评分。
2. 区分公开需求、验证器实际断言、模型实现。只凭最终回复“已完成”或“验证器太严格”不能认定假阴性。
3. 对有明确错误规则的题目复制产物到 analysis/probes，在副本中只修改相关验证器检查，用实验同版本 Godot 4.4.1 headless 运行 scenes/test.tscn，单次最长40秒。
4. 同时保存 pass/fail 标记、退出码和 stderr。通过不等于没有运行警告；脚本崩溃/超时记为不确定，不能当模型能力失败或通过。

本次是全量记录/验证器梳理，加 16 个重点案例的动态复测，不是 380 个案例全部重新运行，也不是全部画面逐帧人工评阅。副本使用 headless 是为了检查结构和逻辑，不能替代原实验的视频/渲染评价。

## 3. 三类已复现问题

### 3.1 错误枚举常量：把 Expand Fill 写成 4

task_0093 与 task_0150 的公开要求都是按钮水平 Expand Fill，验证器却分别对 ContinueButton 和 RestartButton 使用 `size_flags_horizontal != 4`。

同版本 Godot 实测：`Control.SIZE_EXPAND_FILL = 3`，`Control.SIZE_SHRINK_CENTER = 4`。所以模型设成 3 恰好满足要求，却被判错。副本只将两处常量改为 `Control.SIZE_EXPAND_FILL`。

复测结果：0093 四模型全部通过；0150 的 Astra、Sol、Kimi 通过。DeepSeek 0150 仍失败在 VBoxContainer 的居中 anchor，并没有因为修复一处规则而被算成通过。**确认 7 份规则误拒绝**，其中 DeepSeek 0093 原先求解超时。

改进：使用引擎命名常量，建立 prompt→枚举映射测试；同一模板变体共享验证逻辑。不要为了兼容错误标准，把正确的 3 改成 4。

### 3.2 隐含实例名：用名称代替功能定位

task_0028 公开要求在 Main 下放置三个 FlashlightPoint，规定脚本、组、坐标和优先级，但没有规定 PillarPoint、GatePoint、EnemyPoint 三个实例名。官方验证器按这三个名字取节点，因此四模型都在 `PillarPoint node missing` 处停止。

产物实际使用 FlashlightPoint、FlashlightPoint2、FlashlightPoint3。副本仅替换验证器查找的这三个实例名，保留类型、组、脚本、方法、优先级、初始状态和位置容差检查。

Astra、Sol、Kimi 通过；DeepSeek 随后失败于“不是 Marker3D”。因此这里只确认 **3 份**，不将 DeepSeek 计入；其 Marker3D 要求是否也过窄需要单独判断，不能通过连删断言把它变成假阴性。

改进：按公开约定的组/脚本识别候选，再做坐标与优先级的一一匹配；如果实例名是外部接口的一部分，就必须写进任务描述。复测中的固定别名映射是诊断工具，不是建议发布的通用验证器。

### 3.3 只查 Mesh 资源槽：忽略最终生效的覆盖材质

task_0107 原版读取 `mesh.surface_get_material(0)` 判断 shader 是否应用。MeshInstance3D 可以通过覆盖材质让 shader 真正生效，但底层 Mesh 槽仍是原材质。四模型均在这处失败。

副本保留调用 shader 应用函数、FOV=54、路径、albedo/metallic/roughness 复制检查，只把应用后的读取改成 `mesh_instance.get_active_material(0)`，应用前的基础材质读取保持不变。

Astra、Kimi 通过后续所有原版检查，确认 **2 份**。Sol、DeepSeek 在后续 albedo 检查出现 Nil→Color 类型错误并超时；这可能涉及参数设置/读取路径，不能据当前结果确认整个案例属于假阴性。

另一个确定问题：该题成功路径打印 `VALIDATION_PASSED` 后仍 `quit(1)`，导致成功标记与退出码矛盾。复测表保留了这个现象，依据标记和源码解释，不能简单把 exit=1 当复测失败。正式修复应成功退出0，并将脚本异常独立为 evaluator_error。

## 4. 全部重点复测记录

'''+table(['模型','任务','原求解正常','局部修正规则后的消息','退出码'],probe_table)+'''
结果文件：[原始12次复测](../analysis/probe_results.json)、[4次命名复测](../analysis/probe_results_task_0028.json)。逐条日志位于对应 analysis/probes/模型_任务/audit_probe.log；[复测脚本](../analysis/probe_saved.py)记录了具体变更。原始产物没有被改动。

若仅把上述已确认12份在一个**审计敏感性口径**中计为通过，结果从35/380变成47/380（12.4%）；这不是新的官方成绩。Astra增加4，Sol增加3，DeepSeek增加1，Kimi增加4。即使修复这些规则，大多数问题仍未解决，不能将全部低分归咎于评测器。

## 5. 其他高风险检查：候选与反例

'''+table(['问题/任务','已有证据','当前判断','还需什么证据'],[
['指定函数词法：0055','四模型正常结束，均因缺少snappedf字符串拒绝；产物使用round/roundi或snapped量化45度','确认检查过窄；尚不计整个案例已合格','抽样62831个角度round与snappedf方向编号一致；仍需验证8方向动画、死区、点击和移动边界'],
['指定回调名：0002','Astra/DeepSeek正常结束但被要求存在_on_area_entered；prompt描述碰撞行为未规定回调名；Sol/Kimi通过','高风险候选','发出真实overlap信号，核对连接、敌人判定、任务进度和释放；不能只检查任意同义函数存在'],
['额外颜色约束：宝石题','首个失败有7次purple/pink-purple tint，其中3次正常结束；如0240公开描述要求半透明并覆盖宝石','公开要求与美术偏好可能不一致','逐题核对prompt与图片是否明确要求颜色；先确认形状/位置/透明度是否合格'],
['固定几何参考与IoU阈值：27题','金币11、星星11、宝石5，使用polygon_iou与手写预期几何；金币0.90、星星0.85等','有标注/容差风险，未确认误判','审查参考mask、图片分辨率及坐标变换；双人标注与阈值敏感性，不凭“看着差不多”放行'],
['明确要求的节点缺失：Kimi0216/0227','CoinHighlights或StarHighlight缺失；节点名在公开要求中明确','已有交付缺陷，不属于命名自由引起的假阴性','若要复核只能检查产物/运行时是否另行生成，不应把所有名字检查都删掉'],
['跨状态行为：0281—0291','验证器模拟拖拽、短时释放、取消、进入退出目标和提交销毁','行为验证方向合理；31/33求解未正常结束','控制随机与时钟，检查公开接口一致性；当前无证据把0通过归因为误判']])+'''
注意：0055 的数学抽样只覆盖角度量化，不是完整行为等价证明；规则可以严格，只要严格程度对应公开任务目标、正确的引擎语义和可复现测量。

## 6. 官方验证器具体用了什么方法

整体是 Godot 场景运行中的断言，失败大多打印第一条 `VALIDATION_FAILED` 后退出，全部满足才打印 `VALIDATION_PASSED`，不是统一的视觉质量模型打分。

'''+table(['方法','具体做法/案例','优势','盲点'],[
['文件与场景结构','检查资源存在、节点路径、类型、脚本、组、材质与Shader路径','可重复、定位快','把内部实现当接口会拒绝等价方案'],
['属性与数值','位置、anchor、颜色、FOV、优先级、半径、碰撞配置及容差','解释清楚、易自动化','错误常量、未公开参数、阈值不合理'],
['源代码字符串','如0055要求出现snappedf/wrapi等；部分Shader要求特定表达式','成本低','语义等价被拒；注释含词也可能误通过'],
['函数/信号/事件行为','UI的show_screen与暂停；卡牌输入、状态转换与对象释放','更接近实际功能','回调名/测试时序耦合，环境异常误算失败'],
['几何代理指标','Polygon2D变换后的顶点与固定参考多边形算IoU','可量化位置和轮廓','不等于渲染后的真实可见效果；参考多边形质量关键'],
['场景组合约束','相机、球体、水面材质和物体相对配置','较适合教程步骤的精确复现','通过结构检查不代表视觉自然、时序稳定或交互无缺陷']])+'''
对104份脚本的可复现文本扫描：27份定义 polygon_iou；7份含 `.contains(`/`.find(`/`.findn(`；35份出现 await；76份出现 abs、distance_to 或 is_equal_approx；23份匹配指定的函数调用/输入处理模式。这些数字只是代码模式覆盖数，互相重叠，正则也有漏检，不能用作严格的“某类验证方法占比”。脚本与扫描表达式见 analysis/stats.py。

## 7. 高频问题与改进优先级

### P0：先修会直接改变对错的工程错误

- 用引擎常量代替魔法数字；为枚举、材质生效路径、坐标变换写微型测试。
- 统一成功标记、退出码与异常结果。输出结构化 JSON：check_id、expected、actual、status、evidence；无法执行验证应是 evaluator_error。
- 在安全可继续的检查间收集多个失败点。依赖前置条件的检查标为 blocked，不继续触发 Nil 类型错误。
- 保留当前所有原版结果；修复后另设 validator_version 和审计结果列，不能悄悄改榜。

### P1：把“教程实现细节”改成“公开可验收契约”

- 每条断言映射到一条公开需求；隐藏标准要么删去，要么在新版本任务描述中公开。
- 允许等价实现：实例名非接口时按组/属性匹配；材质检查effective结果；数学函数按输出行为测试。
- 保留必要约束：公开规定的路径、名字、函数接口、范围仍应校验；不以降低要求换通过率。
- 每题至少维护标准正确实现、一个等价正确实现、多个明确错误变体。确认正确实现都能通过，错误变体不能轻易通过；同时测试假阴性与假阳性。

### P2：加强视觉与动态任务的Rubric

- 视觉定位采用版本化参考mask和标注说明；将目标检测、坐标转换、轮廓精度、可见透明度分项计分。对IoU报告连续值、阈值附近的复核区间及标注一致性，不只有0/1。
- shader任务同时检查编译、实际生效材质、参数传播、固定机位图像、相机运动与时间变化。静态场景结构只能作为其中一部分。
- 交互任务使用确定性事件回放、固定时钟/帧数和明确重置；覆盖正常、取消、重复信号、边界时长，分别记录状态与视觉证据。
- 对可能的主观美术标准建立公开文字锚点和正反例；自动评分不确定时进入人工双盲复核。模型评审只能辅助，不能自己宣布自己成功，也不能替代可执行证据。

建议保留官方严格二元结果供历史比较，同时新增四维诊断rubric：①资源/结构有效，②核心行为正确，③视觉/几何达标，④鲁棒性和边界行为。每项记录满分条件、部分完成条件、失败条件、证据来源与是否适用；不适用项不扣分。权重应按任务目标预注册，不能为了本批结果事后调权。

## 8. 如何验证新Rubric真的更好

用独立人工判定的小型平衡集，包含正确等价实现、真正错误、临界视觉样例和环境失败。报告假阴性率、假阳性率、评审一致性、重跑稳定性、验证耗时；由不知模型身份的两位评审按同一公开Rubric判断分歧。设计与测试按模板族分离，防止在同一图像变体上调阈值再宣称泛化。

审计时不把隐藏验证器反馈给求解模型。若另做“评测反馈修复Agent”，必须独立命名实验和预算，不能与原始一次求解成绩混报。

## 9. 可追溯材料

- [逐题审计索引](逐题审计索引.csv)：104题、四模型状态及首个失败点、审计级别。
- [逐案例原始指标](../analysis/case_table.csv)、[完整快照](../analysis/case_metrics.json)。
- [复测结果](../analysis/probe_results.json)、[命名复测](../analysis/probe_results_task_0028.json)、[复测脚本](../analysis/probe_saved.py)。
- [枚举与数学抽样脚本](../analysis/enum_probe/probe.gd)、[输出](../analysis/enum_probe/probe.log)。
- 原版104份validator均保存在 analysis/task_XXXX_validator.gd；项目原始轨迹地址逐案例记录在CSV，保留失败信息和模型可见回复。

当前没有将本地材料发给外部Astra评审，没有发布或推送原始实验数据。本篇结论由本地证据审计产生；可疑案例不包装成已证实假阴性，修复一个断言也不代表整个任务获得全面独立验收。
'''
(OUT/'02_假阴性与Rubric改进.md').write_text(report2,encoding='utf8')
with (OUT/'逐题审计索引.csv').open('w',encoding='utf-8-sig',newline='') as f:
 fields=['task','category']+[m+'_'+s for m in models for s in ['state','official_success','solver_success','first_message','audit']]
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
 for t in tasks:
  row={'task':t['task'],'category':t['category']}
  for m in models:
   r=next(r for r in rows if r['model']==m and r['task']==t['task'])
   tag='局部规则修正后其余原版检查通过' if (m,t['task']) in confirmed else ('候选：未完成独立行为验收' if t['task'] in ['task_0055','task_0002'] and not r.get('official_success') and r['state']=='completed' else '记录已梳理；未确认假阴性')
   if r['state']!='completed':tag='未完成，不参与评分'
   for s,val in [('state',r['state']),('official_success',r.get('official_success','')),('solver_success',r.get('solver_success','')),('first_message',r.get('official_message','')),('audit',tag)]:row[m+'_'+s]=val
  w.writerow(row)
print('Wrote two reports and 104-task audit index. Confirmed rule-caused rejections:',len(confirmed))
