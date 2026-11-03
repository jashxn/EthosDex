#!/usr/bin/env sh
# Bundles src/ into dist/EthosDex.lua, the file executors run. Needs Lune (see aftman.toml).
set -e
cd "$(dirname "$0")/.."
mkdir -p dist
lune run lune/wax.luau bundle input=default.project.json output=dist/EthosDex.lua minify=false ci-mode=true
echo "built dist/EthosDex.lua ($(wc -c < dist/EthosDex.lua) bytes)"
