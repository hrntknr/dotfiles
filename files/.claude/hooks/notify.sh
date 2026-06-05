#!/bin/bash -eu

input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
message=$(echo "$input" | jq -r '.message // .last_assistant_message // empty' | head -1)

url=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  url=$(grep 'bridge_status' "$transcript_path" | tail -1 | jq -r '.url // empty')
fi

ntf --title "Claude Code" --url "$url" --group "$session_id" "$message" || true
