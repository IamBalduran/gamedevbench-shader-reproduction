#!/usr/bin/env bash
set -euo pipefail
base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$base/../gamedevbench-main/gamedevbench-main"
mkdir -p "$base/tools" "$base/logs" "$HOME/.local/bin"
curl -fLsS --retry 2 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz' -o "$base/tools/uv.tar.gz"
tar -xzf "$base/tools/uv.tar.gz" -C "$base/tools"
curl -fLsS --retry 2 'https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip' -o "$base/tools/godot.zip"
python3 -m zipfile -e "$base/tools/godot.zip" "$base/tools"
chmod +x "$base/tools/Godot_v4.4.1-stable_linux.x86_64"
curl -fLsS --retry 2 'https://github.com/anomalyco/opencode/releases/download/v1.18.32/opencode-linux-x64.tar.gz' -o "$base/tools/opencode-linux-x64.tar.gz"
tar -xzf "$base/tools/opencode-linux-x64.tar.gz" -C "$HOME/.local/bin" opencode
chmod +x "$HOME/.local/bin/opencode"
cd "$repo"
"$base/tools/uv-x86_64-unknown-linux-gnu/uv" sync --locked --python 3.11
python3 - "$repo" <<'PY'
import json, pathlib, sys
repo = pathlib.Path(sys.argv[1]).resolve()
path = repo / 'opencode.json'
config = json.loads(path.read_text(encoding='utf-8'))
config['plugin'] = [(repo / 'gamedevbench/shubiaobiao_plugin.mjs').as_uri()]
path.write_text(json.dumps(config, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
PY
"$base/tools/Godot_v4.4.1-stable_linux.x86_64" --version
"$HOME/.local/bin/opencode" --version
echo 'Environment ready; no benchmark task was started.'
