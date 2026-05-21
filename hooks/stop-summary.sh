#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
session_id="${session_id:-${CLAUDE_SESSION_ID:-unknown}}"

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
audit_dir="${project_dir}/.claude/audit"
tmp_dir="${audit_dir}/tmp/${session_id}"

mkdir -p "$audit_dir"

ended_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

count_lines() {
  local f="$1"
  [[ -f "$f" ]] && awk 'END{print NR+0}' "$f" || echo 0
}

pre_count=$(count_lines "${tmp_dir}/pre")
post_count=$(count_lines "${tmp_dir}/post")
subagent_calls=$(count_lines "${tmp_dir}/subagent")

jq -n \
  --arg  session_id          "$session_id" \
  --arg  ended_at            "$ended_at" \
  --argjson pre_tool_use_count  "$pre_count" \
  --argjson post_tool_use_count "$post_count" \
  --argjson subagent_calls      "$subagent_calls" \
  '{
    session_id:           $session_id,
    ended_at:             $ended_at,
    pre_tool_use_count:   $pre_tool_use_count,
    post_tool_use_count:  $post_tool_use_count,
    subagent_calls:       $subagent_calls
  }' > "${audit_dir}/summary-${session_id}.json"

rm -rf "$tmp_dir"
