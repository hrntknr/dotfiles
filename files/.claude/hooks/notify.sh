#!/bin/bash -eu

input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id')
transcript_path=$(echo "$input" | jq -r '.transcript_path')
message=$(echo "$input" | jq -r '.message // .last_assistant_message // empty' | head -1)

url=$(grep 'bridge_status' "$transcript_path" | tail -1 | jq -r '.url // empty')

if [ -z "${BARK_KEY:-}" ] || [ -z "${BARK_DEVICE:-}" ] || [ -z "${BARK_IV:-}" ]; then
  exit 0
fi

json=$(jq -n --arg title "Claude Code" --arg body "$message" --arg url "$url" --arg group "$session_id" \
  '{title: $title, body: $body, url: $url, group: $group}')

key=$(printf '%s' "$BARK_KEY" | xxd -ps -c 200)
iv=$(printf '%s' "$BARK_IV" | xxd -ps -c 200)

ciphertext=$(echo -n "$json" | openssl enc -aes-128-cbc -K "$key" -iv "$iv" | base64)

curl -s --data-urlencode "ciphertext=$ciphertext" "https://api.day.app/$BARK_DEVICE/" > /dev/null 2>&1
