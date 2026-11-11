#!/bin/sh
# Copy src/ and build/ into checkpoints/<label>_<time>. Usage: tools/checkpoint.sh label
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; L="${1:-checkpoint}"; T="$(date +%H%M)"
mkdir -p "$ROOT/checkpoints/${L}_$T" && cp -R "$ROOT/src" "$ROOT/build" "$ROOT/checkpoints/${L}_$T/" && echo "checkpoint: checkpoints/${L}_$T"
