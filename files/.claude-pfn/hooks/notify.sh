#!/bin/bash -eu

input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id')
transcript_path=$(echo "$input" | jq -r '.transcript_path')
message=$(echo "$input" | jq -r '.message // .last_assistant_message // empty' | head -1)

url=$(grep 'bridge_status' "$transcript_path" | tail -1 | jq -r '.url // empty')

ntf --title "Claude Code" --url "$url" --group "$session_id" "$message"
