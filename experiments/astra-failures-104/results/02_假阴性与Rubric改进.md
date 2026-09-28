# 已有实验结果：假阴性与 Rubric 改进

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

| 模型 | 任务 | 原求解正常 | 局部修正规则后的消息 | 退出码 |
| --- | --- | --- | --- | --- |
| GPT-6 Astra | task_0093 | 是 | VALIDATION_PASSED: Task completed successfully | 0 |
| GPT-6 Astra | task_0107 | 是 | VALIDATION_PASSED: View model shader applied and configured | 1 |
| GPT-6 Astra | task_0150 | 是 | VALIDATION_PASSED: Task completed successfully | 0 |
| GPT-5.6 Sol | task_0093 | 是 | VALIDATION_PASSED: Task completed successfully | 0 |
| GPT-5.6 Sol | task_0107 | 是 | 后续脚本类型错误，40秒终止 | timeout |
| GPT-5.6 Sol | task_0150 | 是 | VALIDATION_PASSED: Task completed successfully | 0 |
| DeepSeek V4 Pro | task_0093 | 否 | VALIDATION_PASSED: Task completed successfully | 0 |
| DeepSeek V4 Pro | task_0107 | 是 | 后续脚本类型错误，40秒终止 | timeout |
| DeepSeek V4 Pro | task_0150 | 否 | VALIDATION_FAILED: VBoxContainer must be centered with 0.5 anchors | 1 |
| Kimi K3 | task_0093 | 是 | VALIDATION_PASSED: Task completed successfully | 0 |
| Kimi K3 | task_0107 | 是 | VALIDATION_PASSED: View model shader applied and configured | 1 |
| Kimi K3 | task_0150 | 是 | VALIDATION_PASSED: Task completed successfully | 0 |
| GPT-6 Astra | task_0028 | 是 | VALIDATION_PASSED: Flashlight priority points configured | 0 |
| GPT-5.6 Sol | task_0028 | 是 | VALIDATION_PASSED: Flashlight priority points configured | 0 |
| DeepSeek V4 Pro | task_0028 | 是 | VALIDATION_FAILED: FlashlightPoint is not a Marker3D | 1 |
| Kimi K3 | task_0028 | 是 | VALIDATION_PASSED: Flashlight priority points configured | 0 |

结果文件：[原始12次复测](../analysis/probe_results.json)、[4次命名复测](../analysis/probe_results_task_0028.json)。逐条日志位于对应 analysis/probes/模型_任务/audit_probe.log；[复测脚本](../analysis/probe_saved.py)记录了具体变更。原始产物没有被改动。

若仅把上述已确认12份在一个**审计敏感性口径**中计为通过，结果从35/380变成47/380（12.4%）；这不是新的官方成绩。Astra增加4，Sol增加3，DeepSeek增加1，Kimi增加4。即使修复这些规则，大多数问题仍未解决，不能将全部低分归咎于评测器。

## 5. 其他高风险检查：候选与反例

| 问题/任务 | 已有证据 | 当前判断 | 还需什么证据 |
| --- | --- | --- | --- |
| 指定函数词法：0055 | 四模型正常结束，均因缺少snappedf字符串拒绝；产物使用round/roundi或snapped量化45度 | 确认检查过窄；尚不计整个案例已合格 | 抽样62831个角度round与snappedf方向编号一致；仍需验证8方向动画、死区、点击和移动边界 |
| 指定回调名：0002 | Astra/DeepSeek正常结束但被要求存在_on_area_entered；prompt描述碰撞行为未规定回调名；Sol/Kimi通过 | 高风险候选 | 发出真实overlap信号，核对连接、敌人判定、任务进度和释放；不能只检查任意同义函数存在 |
| 额外颜色约束：宝石题 | 首个失败有7次purple/pink-purple tint，其中3次正常结束；如0240公开描述要求半透明并覆盖宝石 | 公开要求与美术偏好可能不一致 | 逐题核对prompt与图片是否明确要求颜色；先确认形状/位置/透明度是否合格 |
| 固定几何参考与IoU阈值：27题 | 金币11、星星11、宝石5，使用polygon_iou与手写预期几何；金币0.90、星星0.85等 | 有标注/容差风险，未确认误判 | 审查参考mask、图片分辨率及坐标变换；双人标注与阈值敏感性，不凭“看着差不多”放行 |
| 明确要求的节点缺失：Kimi0216/0227 | CoinHighlights或StarHighlight缺失；节点名在公开要求中明确 | 已有交付缺陷，不属于命名自由引起的假阴性 | 若要复核只能检查产物/运行时是否另行生成，不应把所有名字检查都删掉 |
| 跨状态行为：0281—0291 | 验证器模拟拖拽、短时释放、取消、进入退出目标和提交销毁 | 行为验证方向合理；31/33求解未正常结束 | 控制随机与时钟，检查公开接口一致性；当前无证据把0通过归因为误判 |

注意：0055 的数学抽样只覆盖角度量化，不是完整行为等价证明；规则可以严格，只要严格程度对应公开任务目标、正确的引擎语义和可复现测量。

## 6. 官方验证器具体用了什么方法

整体是 Godot 场景运行中的断言，失败大多打印第一条 `VALIDATION_FAILED` 后退出，全部满足才打印 `VALIDATION_PASSED`，不是统一的视觉质量模型打分。

| 方法 | 具体做法/案例 | 优势 | 盲点 |
| --- | --- | --- | --- |
| 文件与场景结构 | 检查资源存在、节点路径、类型、脚本、组、材质与Shader路径 | 可重复、定位快 | 把内部实现当接口会拒绝等价方案 |
| 属性与数值 | 位置、anchor、颜色、FOV、优先级、半径、碰撞配置及容差 | 解释清楚、易自动化 | 错误常量、未公开参数、阈值不合理 |
| 源代码字符串 | 如0055要求出现snappedf/wrapi等；部分Shader要求特定表达式 | 成本低 | 语义等价被拒；注释含词也可能误通过 |
| 函数/信号/事件行为 | UI的show_screen与暂停；卡牌输入、状态转换与对象释放 | 更接近实际功能 | 回调名/测试时序耦合，环境异常误算失败 |
| 几何代理指标 | Polygon2D变换后的顶点与固定参考多边形算IoU | 可量化位置和轮廓 | 不等于渲染后的真实可见效果；参考多边形质量关键 |
| 场景组合约束 | 相机、球体、水面材质和物体相对配置 | 较适合教程步骤的精确复现 | 通过结构检查不代表视觉自然、时序稳定或交互无缺陷 |

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
