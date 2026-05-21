#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

if [[ -z "$file_path" ]]; then
  exit 0
fi

ext="${file_path##*.}"
if [[ "$ext" != "md" && "$ext" != "markdown" ]]; then
  exit 0
fi

if [[ ! -f "$file_path" ]]; then
  exit 0
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
comment="<!-- 更新: ${timestamp} -->"

# Update existing timestamp on first line, or prepend
if sed -n '1p' "$file_path" | grep -qE '^<!-- 更新: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} -->$'; then
  sed -i '' "1s|.*|${comment}|" "$file_path"
else
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  { printf '%s\n' "$comment"; cat "$file_path"; } > "$tmp" && mv "$tmp" "$file_path"
fi

# Normalize trailing newlines to exactly one (command substitution strips all trailing newlines)
content=$(cat "$file_path")
printf '%s\n' "$content" > "$file_path"
