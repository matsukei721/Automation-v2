#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

if [[ -z "$command" ]]; then
  exit 0
fi

check_pattern() {
  local pattern="$1"
  local reason="$2"
  if echo "$command" | grep -qE "$pattern"; then
    echo "BLOCKED: $reason" >&2
    echo "Command: $command" >&2
    exit 2
  fi
}

check_pattern 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r' \
  "rm -rf は危険な再帰削除のため実行をブロックしました"

check_pattern 'curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?sh\b|curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?bash\b|wget[^|]*\|[[:space:]]*(sudo[[:space:]]+)?sh\b|wget[^|]*\|[[:space:]]*(sudo[[:space:]]+)?bash\b' \
  "curl|sh / wget|sh はリモートスクリプト実行のため実行をブロックしました"

check_pattern '\bsudo\b' \
  "sudo は特権昇格のため実行をブロックしました"

check_pattern '\bdd\s+if=' \
  "dd if= はディスク直接書き込みのため実行をブロックしました"

check_pattern '\bmkfs\b' \
  "mkfs はファイルシステム破壊のため実行をブロックしました"

exit 0
