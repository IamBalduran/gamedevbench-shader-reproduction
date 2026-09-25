# Shader 子集筛选与后续判分审计

当前实验仅运行 `shader_task_selection.json` 中的 12 个任务：7 个要求编写 Shader、VisualShader 或 GLSL；5 个要求配置或驱动 ShaderMaterial。`shader_task_inventory.csv` 保存全部 333 题的说明、关键词匹配和分类，另有 12 题提及 Shader 但主要测试场景搭建，因此未纳入主实验。筛选可复核，不以项目中碰巧存在 `.gdshader` 文件作为入选条件。

`official_failures.csv`、`official_failures.jsonl`、`official_failure_summary.json`、`validator_review_queue.csv` 和 `method_contract_candidates.csv` 是作者发布结果和验证器的筛选资料，不是本地实验成绩。它们保留用于实验完成后的误判审计。

此前非 Shader 的本地试跑产物、检查点和案例审计已按用户要求清理。新的本地结果只写入 `../batch_runs/gpt6_astra_shader/` 及 GameDevBench 的逐题原始结果目录。官方评分和后续研究者的行为复核将分别记录，不修改原验证器成绩。
