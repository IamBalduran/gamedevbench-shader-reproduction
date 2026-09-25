# Shader 子集：48 次运行与验证器复核

日期：2026-09-25。范围：12 道 Shader 相关任务 × 4 个模型，每题一份最终记录。原始数据见 `results/comparison_portable.csv`；每行的 `artifact_dir`、`result_json`、`trajectory_log` 可追溯到具体产物。作者对照数据为 `gamedevbench-main/gamedevbench-main/results/gpt6_astra_codex_runtime_video_high_full_333/final_results.json`。本报告保留官方判分，不修改原验证器或原始产物。

## 先看结论

| 模型 | 官方通过 | 求解器正常结束 | 两者都满足 |
|---|---:|---:|---:|
| GPT-6 Astra | 7/12 | 10/12 | 7/12 |
| GPT-5.6 Sol | 4/12 | 8/12 | 3/12 |
| DeepSeek V4 Pro | 2/12 | 4/12 | 1/12 |
| Kimi K3 | 3/12 | 8/12 | 2/12 |

48 份记录中有 16 份获官方通过、32 份未通过；18 次求解器未正常结束，包括 17 次超时和 1 次进程异常。另有 3 次虽超时，已保存的代码仍通过官方验证。因此“运行结束”“求解完成”“验证通过”不能混作一个指标。Kimi 的 task_0033 记录了异常长的墙钟时间，应按超时处理，不把该值当作实际模型计算时间。

同一组 12 题上，作者发布的 GPT-6 Astra（Codex）和本地 Astra（OpenCode）均为 **7/12**，逐题判定和首条验证消息完全一致；但代理、供应商路径、并发数不同。作者全量 **229/333** 与本次 **7/12** 的题目分母不同，不能直接比较百分比。其他三个模型没有找到同配置的作者逐题基线。

## 12 题逐题核对

表中 A＝Astra，S＝Sol，D＝DeepSeek，K＝Kimi；“超时”指求解器未正常结束，即使验证器仍能检查当时保存的文件。判断栏是本报告的独立审计，不替换官方分数。

| 任务 | 官方通过 | 四模型表现与首个阻断点 | 审计判断 |
|---|---:|---|---|
| 0019 枪口火焰 | 0/4 | A/S/K 把火焰 ShaderMaterial 放在 QuadMesh 上，粒子节点的 `material_override` 为空；D 超时且同样报此项。 | **明确实现偏差**：题目明确要求粒子节点使用该材质；视觉上可能仍有火焰，但不满足指定结构。 |
| 0033 粒子烟雾 | 0/4 | 四者均超时。A/S 的 `ArcingChunks.material_override` 缺失；K 仍是默认寿命；D 报 `Explosion` 未找到，虽保存场景中有该节点，加载原因尚未确定。 | **求解未完成**，不能据第一条错误判断整个粒子效果；D 的场景加载问题需单独复现。 |
| 0057 单位光环 | 0/4 | 四者都沿用 `player.tscn`，验证器只认可 `unit.tscn` 的实例。改路径的隔离副本显示 S/D 后续还有脚本问题；K 的选择光环在原产物中实测可切换。A 进程异常且脚本基本未实现。 | **K 属行为达成但结构契约有争议**；主任务说明未写出路径，元数据写了 `unit.tscn`，验证器硬编码后者。不能把 S/D/A 的失败全算假阴性。 |
| 0095 CRT | 0/4 | 四份 shader 都有曲率、越界遮罩、扫描线、暗角、LOD 采样，但公式、变量写法或空格与验证器的固定字符串不同。 | **假阴性候选**：源码覆盖了描述性要点；尚无独立画面质量对照，不能确认四份视觉上都达标。 |
| 0096 像素化 | 1/4：A | S/D/K 都未写 `render_mode unshaded`；D 同时超时。 | **明确实现偏差**：这是任务的显式要求，虽然其余像素化代码存在。 |
| 0097 UV 扭曲 | 1/4：A | S 的场景文本看似存了 7、5、0.1，但 Godot 4.4.1 实际加载后四个端口全为 0；D/K 超时且预览节点无 ShaderMaterial。 | **不是 S 的假阴性**：运行值确实错误。仅看 `.tscn` 文本会误判。 |
| 0100 地图边缘平滑 | 2/4：A、K | D 有对角邻域混合函数 `diagonal_line_blend(...)`，却因验证器只找 `diag(` 被判失败；S 也用其他函数名，但超时。 | **D 为高可信假阴性候选**：命名不影响算法存在；尚未确认实际画面达到预期 HQX 质量。S 需先解决未完成状态。 |
| 0106 深度描边 | 3/4：A、S、D | S/D 均超时但保存的文件通过；K 超时，使用按 `view` 索引读取颜色层，验证器只接受字面量 `get_color_layer(0)`。 | **结果可靠性有限**：验证器仅搜源码片段，不执行 compute 管线或检验描边画面；K 的实现又未完成，不能据此改判。 |
| 0107 武器 Shader | 0/4 | A/K 正常结束，却报“Surface material is not a ShaderMaterial”；S 同报但超时；D 在更早的基础材质检查失败且超时。 | **A/K 已确认验证器假阴性**：Godot 实测实际生效材质为正确 ShaderMaterial，FOV＝54，albedo/metallic/roughness 均复制正确；验证器读了另一个材质层。 |
| 0110 基础三平面 | 4/4 | 四份均通过。 | 官方检查场景、材质、贴图参数和若干固定公式；**没有检验实际三轴投影画面**。 |
| 0111 顶部草地三平面 | 3/4：A、S、K | D 超时且 SphereMesh 上未挂 ShaderMaterial。 | D 的保存产物不满足结构要求；验证器其余部分仍依赖精确公式片段。 |
| 0128 Julia 面板 | 2/4：A、S | D 超时，面板缺少 `GROW_DIRECTION_BOTH`；K 没有创建 Panel。 | 主要是未完成或场景配置缺失；K 非假阴性。本题测的是面板与材质参数，几乎不是生成 shader 的能力。 |

## 验证器究竟怎样判分

这 12 题主要用了三类方法：

1. **场景和资源属性检查**：读取节点类型、路径、材质槽、shader 资源路径、参数值。例如 0019、0033、0096、0110、0128。优点是明确、可重复；缺点是可能只接受一种资源组织方式。
2. **源代码固定字符串检查**：搜索精确公式、函数名、调用形式或小数格式。例如 0095 的 CRT 公式、0100 的 `diag(`、0106 的 `get_color_layer(0)`、0110/0111 的逐字三平面表达式。这能检查教程式写法，却会排斥等价实现，也可能被无效但含关键词的代码骗过。
3. **少量运行时行为检查**：0057 调用选择/目标设置；0107 调用材质替换函数。这里仍主要检查值，而非观察渲染结果。**本子集的官方验证器没有基于多帧画面、视角变化或图像相似度给分。**

发现两类额外的判分实现问题：0057 的深层检查失败后仍可继续打印 `VALIDATION_PASSED`，隔离反事实测试出现了同一次执行既有失败又有通过标记；0100、0107、0111、0128 的成功分支仍调用 `quit(1)`，若外部只看进程退出码就会与文本结果冲突。当前官方汇总以其现有解析口径为准，但这些实现使二次复核更困难。

## 假阴性分级与修正建议

- **已证实当前报错点的结构性假阴性：2 条（0107 A/K）**。官方检查 `mesh.surface_get_material(0)`，而模型设置的是 `MeshInstance3D.set_surface_override_material(0, ...)`。Godot 4.4.1 的 `get_active_material(0)` 实测返回 ShaderMaterial，并且关键参数正确。应该先读取实际生效材质，再核验 shader 路径与参数；只有任务明确要求修改 Mesh 资源本身时，才限定 `surface_get_material`。这证实当前失败理由错误；尚未用独立视觉测试证明整个效果完美。Godot [MeshInstance3D 文档](https://docs.godotengine.org/en/4.4/classes/class_meshinstance3d.html)与 [Mesh 文档](https://docs.godotengine.org/en/4.4/classes/class_mesh.html)也明确区分这两层。
- **高可信但仍需画面复核：0100 D、0095 的四份产物**。0100 不应把函数名固定为 `diag`；0095 不应把一种扫描线/暗角/UV 公式当成唯一正确写法。可先检查 shader 编译与输入输出，再在固定测试图上比较畸变、扫描线、边缘平滑等功能；允许不同公式达到同一可观察目标。
- **契约歧义：0057 K**。主任务说明未明确 `unit.tscn` 路径，但任务元数据的 `expected_nodes` 包含该路径；初始项目的 Main 本就实例化 `player.tscn`。K 的两个实例拥有独立 ShaderMaterial，选择时 `aura_width` 在 1.0/0.0 间切换。应在面向模型的任务说明中明确必须新建 `unit.tscn`，或接受有相同行为的场景，并检查实际实例类型和行为，而非只看 `scene_file_path`。
- **不能改判：0097 S、0096 S/D/K、0019 A/S/K**。0097 的运行时常量确实变为 0；另两题分别漏了明确要求的渲染模式或材质位置。求解器超时的记录也应单列，避免当作完整作品的能力结论。

建议验证器输出每项检查的结构化结果，而不是遇到第一处错误就退出；统一成功标记与退出码；为 shader 增加编译、参数、关键像素/多帧和视角变化的分层检查。公式或场景路径只有在题目明确要求时才作为硬门槛。原始官方分数保持不变，审计标记单独保存，便于日后复核。

## 可复核证据

- 本地逐题记录：`results/comparison_portable.csv`；原始场景和源码位于各行 `artifact_dir`。
- 0107 与 0097 的 Godot 4.4.1 隔离探针：`gamedevbench-environment/batch_runs/shader_comparison/audit_probe_final.log`。0107 A/K 均打印 `active=ShaderMaterial`、正确 shader 路径、FOV 54 和三项复制参数为 true；0097 S 打印四个端口均为 0。
- 0057 K 的行为探针：`gamedevbench-environment/batch_runs/shader_comparison/audit_probe_kimi0057.log`；仅改场景文件路径的副本验证：`gamedevbench-environment/batch_runs/shader_comparison/audit_0057_countercheck.log`。原始产物未被修改。
- 实验探针脚本：`gamedevbench-environment/batch_runs/shader_comparison/audit_probe.gd`、`run_audit_probe.sh`、`run_0057_countercheck.sh`。这些是审计工具，不参与原批次打分。

限制：除明确列出的 Godot 探针外，本报告对其他 shader 以代码、场景和原运行日志为证据；没有为每道题追加盲评画面。因此“候选假阴性”不能直接计入修正后的通过率。
