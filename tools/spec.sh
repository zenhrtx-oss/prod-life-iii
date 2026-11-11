#!/bin/sh
# Run the CLI Luau specs. Usage: sh tools/spec.sh [pattern ...]
# Runs every spec/*_spec.lua whose file name contains any pattern (all when none given).
# A spec passes when luau exits 0 and its last non-empty stdout line starts with "SPEC OK".
# Prints "PASS spec/x_spec.lua" or "FAIL spec/x_spec.lua -> <error>"; exit 1 if any spec fails.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP"' EXIT
cd "$ROOT" || exit 1
fails=0
for f in spec/*_spec.lua; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  if [ $# -gt 0 ]; then
    hit=0
    for p in "$@"; do case "$name" in *"$p"*) hit=1 ;; esac; done
    [ "$hit" = 1 ] || continue
  fi
  luau "$f" >"$TMP/out" 2>"$TMP/err"; rc=$?
  last="$(grep -v '^[[:space:]]*$' "$TMP/out" | tail -n 1)"
  ok=0; [ "$rc" = 0 ] && case "$last" in "SPEC OK"*) ok=1 ;; esac
  if [ "$ok" = 1 ]; then echo "PASS $f"; continue; fi
  # luau appends a "stacktrace:" block after the error message; report the message, not a frame
  msg="$(sed '/^stacktrace:$/,$d' "$TMP/err" | grep -v '^[[:space:]]*$' | tail -n 1)"
  [ -n "$msg" ] || msg="$last"
  [ -n "$msg" ] || msg="no output (luau exit $rc)"
  echo "FAIL $f -> $msg"; fails=1
done
exit "$fails"
