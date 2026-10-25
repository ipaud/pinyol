#!/usr/bin/env bash
# The image bridge with a size: a prompt that ends in "@@2304x768" is asked at that size (sheet_jobs.Job has no size field).
set -euo pipefail
prompt="$1"; out="$2"; shift 2
real="$HOME/.claude/skills/gpt-image-bridge/bin/gpt-image-2"
if [[ "$prompt" =~ @@([0-9]+x[0-9]+)$ ]]; then
  size="${BASH_REMATCH[1]}"; prompt="${prompt%@@*}"
  exec "$real" "$prompt" "$out" --size "$size" "$@"
fi
exec "$real" "$prompt" "$out" "$@"
