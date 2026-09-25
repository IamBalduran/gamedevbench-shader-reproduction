#!/usr/bin/env bash
set -u

godot=/mnt/d/ShaderAgent/re/gamedevbench-environment/tools/Godot_v4.4.1-stable_linux.x86_64
root=/mnt/d/ShaderAgent/re/gamedevbench-main/gamedevbench-main/tasks/test_result
cases=(
  'Sol|gpt56_sol_opencode_high_video_20260924_215107_task_0057_9095_retry1/task_0057_opencode_20260924_220151'
  'DeepSeek|deepseek_v4_pro_opencode_high_video_20260924_224713_task_0057_21183_retry1/task_0057_opencode_20260924_230331'
  'Kimi|kimi_k3_opencode_high_video_20260925_001929_task_0057_1615/task_0057_opencode_20260925_002341'
)

for item in "${cases[@]}"; do
  IFS='|' read -r label relative <<< "$item"
  project=$(mktemp -d "/tmp/shader-audit-0057-${label}-XXXX")
  cp -a "$root/$relative/." "$project/"
  cp "$project/scenes/player.tscn" "$project/scenes/unit.tscn"
  sed -i 's#res://scenes/player.tscn#res://scenes/unit.tscn#g' "$project/scenes/main.tscn"
  printf '\n=== %s after only correcting Unit scene path in a copy ===\n' "$label"
  "$godot" --headless --path "$project" res://scenes/test.tscn 2>&1 | grep -E 'VALIDATION_|SCRIPT ERROR|ERROR:|Parser Error' || true
done
