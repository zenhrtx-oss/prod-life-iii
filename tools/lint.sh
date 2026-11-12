#!/bin/sh
# Lint Luau files with selene (Roblox std). Usage, from ok_studio: sh tools/lint.sh src/Path/File.lua [more paths]
# Advisory, not a gate: report new warnings in files you touched. mixed_table matters for anything saved (JSON can't encode mixed tables).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 0 ] && set -- src
ARGS=""
for p in "$@"; do case "$p" in /*) ARGS="$ARGS|$p";; *) ARGS="$ARGS|$ROOT/$p";; esac; done
cd "$ROOT/tools/selene" || exit 2
IFS='|'; set -- ${ARGS#|}; unset IFS
exec selene --display-style quiet "$@"
