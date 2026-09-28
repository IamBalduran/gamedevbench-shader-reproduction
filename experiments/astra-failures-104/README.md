# 官方 Astra 失败题实验 / Published Astra Failure Subset

## 中文

### 当前状态：未完成快照（2026-09-28）

本实验与仓库根目录的12题Shader实验独立。我们从作者发布的Astra/Codex结果中选择求解器正常结束但官方验证失败的104题，使用四模型分别求解。计划416个案例，目前380份完成记录，Kimi剩余36题因API额度耗尽尚未完成，不按失败计分。

| 模型 | 完成记录 | 官方通过 | 求解器正常结束 |
|---|---:|---:|---:|
| GPT-6 Astra | 104/104 | 9 | 70 |
| GPT-5.6 Sol | 104/104 | 9 | 46 |
| DeepSeek V4 Pro | 104/104 | 7 | 23 |
| Kimi K3 | 68/104 | 10 | 54 |

“完成记录”不等于求解成功；380份中有185次求解超时。官方通过共35份。离线审计发现12份产物只修正局部验证规则就能通过其余原版检查，但不会覆盖原始分数；这也不等于完整视觉/行为验收。完整结论见：

- [模型薄弱板块与Agent改进](results/01_模型表现与Agent改进.md)
- [假阴性与Rubric改进](results/02_假阴性与Rubric改进.md)
- [104题逐题索引](results/逐题审计索引.csv)
- [416案例可移植索引](results/comparison_portable.csv)：证据路径相对于本实验目录；未完成项可能没有结果路径。

### 文件与证据

`gamedevbench-main/gamedevbench-main/tasks/`保存104题输入ZIP与解压资源；`tasks/test_result/`保存模型项目、result.json和agent_trajectory.log。官方逐题JSON在该项目的`results/`中。`gamedevbench-environment/batch_runs/`保存检查点、控制台日志和历史汇总。`analysis/`包含本地统计、原版验证器、复测脚本和日志；复测项目副本的重复资源未打包，原始模型项目完整保留。

原始JSON中的本机绝对路径保留为历史证据，换机器请使用可移植索引。报告是中文，README提供中英文说明。外部Astra事后评审没有执行，当前结论来自本地分析，不应将待评审索引误当模型评审结论。密钥、环境缓存和下载的可执行工具不上传。

### 核验与复现

在本实验目录运行 `python verify_snapshot.py`，仅检查文件与哈希，不调用模型。

原环境：Windows+WSL Ubuntu，Godot4.4.1、OpenCode1.18.32、high、runtime video、strict隔离、600秒求解预算、30步、并发2。可在WSL执行 `bash gamedevbench-environment/setup.sh` 安装依赖。正式入口是 `gamedevbench-environment/Run-Official-Failures-Comparison.ps1`；`-Status`只读状态，默认运行会调用模型，`-Stop`停止。

本快照为证据归档，不应直接在历史检查点上做独立重跑。新机器需使用新的输出目录/批次，并按克隆路径配置环境；历史绝对路径不会自动迁移。我们会在原实验完成后更新此快照和报告，保留原始官方结果及审计分离。

题集有困难子集选择偏差和大量同模板变体；官方基线使用Codex，本实验使用OpenCode/Shubiaobiao，不能当作完全一致的受控模型比较。解题模型不接收隐藏验证器；后验审计与求解隔离。上游许可见 [LICENSE](gamedevbench-main/gamedevbench-main/LICENSE)。

## English

### Status: incomplete snapshot (2026-09-28)

This study is independent of the 12-task Shader experiment at the repository root. We selected 104 tasks where the published Astra/Codex run completed its solver but failed official validation, and scheduled four models: **416 planned cases, 380 completed records**. Astra, Sol and DeepSeek have 104 records each; Kimi has 68, with 36 unfinished after provider quota exhaustion. Unfinished cases are not failures.

Official passes are **9, 9, 7 and 10**, respectively; normal solver completions are **70, 46, 23 and 54**. There are 185 solver timeouts. A completed record does not imply a successful solution. Local audit found 12 outputs that passed the remaining original assertions after narrowly correcting validator rules; original scores are preserved, and this is not exhaustive visual/behavioral certification.

### Reports and evidence

- [Model weaknesses and agentic improvements (Chinese)](results/01_模型表现与Agent改进.md)
- [False negatives and rubric improvements (Chinese)](results/02_假阴性与Rubric改进.md)
- [Task-level audit index](results/逐题审计索引.csv)
- [Portable case/evidence index](results/comparison_portable.csv), with paths relative to this experiment directory.

The archive includes 104 input ZIPs, task resources, official validators, generated projects, visible model/tool trajectories, solver results, official results, checkpoints, console logs and local audit scripts/logs. Redundant probe-project copies, credentials, runtime binaries and caches are excluded. Original JSON retains historical absolute paths; use the portable index on another machine. External Astra post-hoc review was not run; queued evidence is not a completed model review.

### Verification and reproduction

Run `python verify_snapshot.py` from this directory for offline file/hash checks. No model is called. The original setup uses Windows/WSL Ubuntu, Godot 4.4.1, OpenCode 1.18.32, high reasoning, runtime video, strict isolation, a 600-second solver timeout, 30 steps and concurrency 2. Run `bash gamedevbench-environment/setup.sh` in WSL to install dependencies; the PowerShell entry is `gamedevbench-environment/Run-Official-Failures-Comparison.ps1`. `-Status` reads state, `-Stop` requests termination, and a normal launch makes paid API calls.

Preserve this evidence snapshot before an independent reproduction. Use fresh batch/output directories and configure the cloned location; historical checkpoint paths are not automatically relocated. We will update results and reports after the remaining Kimi tasks finish. Solver inputs remain separate from hidden validators and post-hoc audit.

This is a selected difficult subset with related task variants. The author baseline uses Codex, whereas this run uses OpenCode/Shubiaobiao, so it is not a controlled model-only comparison. Upstream code/assets retain their respective terms; see [LICENSE](gamedevbench-main/gamedevbench-main/LICENSE).

## 代表性截图 / Representative screenshots

以下截图由真实结果与轨迹摘录渲染，非实时终端截图；轨迹参数有截短，完整原文保存在日志。
These screenshots render saved results and trace excerpts, not a live terminal; tool arguments are shortened and the full logs are retained.

### 四模型结果与未完成状态 / Results and incomplete status

![四模型结果与未完成状态 / Results and incomplete status](docs/screenshots/01-results.png)

### Astra 的工具调用与最终回复 / Astra tool calls and final response

![Astra 的工具调用与最终回复 / Astra tool calls and final response](docs/screenshots/02-trajectory.png)

### 错误枚举断言与离线复测 / Incorrect enum assertion and offline replay

![错误枚举断言与离线复测 / Incorrect enum assertion and offline replay](docs/screenshots/03-validator.png)


发布副本中的一份轨迹已遮盖疑似密钥字符串；本地原始证据未修改。One published trajectory has credential-shaped text redacted; original local evidence is unchanged.
