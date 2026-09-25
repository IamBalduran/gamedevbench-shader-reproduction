#!/usr/bin/env bash
set -u

godot=/mnt/d/ShaderAgent/re/gamedevbench-environment/tools/Godot_v4.4.1-stable_linux.x86_64
probe=/mnt/d/ShaderAgent/re/gamedevbench-environment/batch_runs/shader_comparison/audit_probe.gd
root=/mnt/d/ShaderAgent/re/gamedevbench-main/gamedevbench-main/tasks/test_result

cases=(
  'Kimi_0057|kimi_k3_opencode_high_video_20260925_001929_task_0057_1615/task_0057_opencode_20260925_002341'
  'Astra_0107|gpt6_astra_opencode_high_video_20260924_213521_task_0107_3939/task_0107_opencode_20260924_213928'
  'Kimi_0107|kimi_k3_opencode_high_video_20260925_150915_task_0107_5577/task_0107_opencode_20260925_151614'
  'Sol_0097|gpt56_sol_opencode_high_video_20260924_220331_task_0097_11939/task_0097_opencode_20260924_221217'
)

for item in "${cases[@]}"; do
  IFS='|' read -r label relative <<< "$item"
  if [[ $# -gt 0 && "$label" != "$1" ]]; then
    continue
  fi
  project=$(mktemp -d "/tmp/shader-audit-${label}-XXXX")
  cp -a "$root/$relative/." "$project/"
  printf '\n=== %s ===\n' "$label"
  "$godot" --headless --path "$project" --script "$probe"
  printf 'probe_exit=%s\n' "$?"
done
