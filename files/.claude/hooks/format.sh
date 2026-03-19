#!/usr/bin/env bash
set -euo pipefail

file_path="$(jq -r '.tool_input.file_path // empty')"
[ -n "$file_path" ] || exit 0

case "$file_path" in
  *.rs)
    [ -f Cargo.toml ] && cargo fmt
    ;;
  *.go)
    command -v gofmt >/dev/null && gofmt -w "$file_path"
    ;;
  *.py)
    command -v ruff >/dev/null && ruff format "$file_path"
    ;;
  *.js|*.jsx|*.ts|*.tsx|*.json|*.md|*.css|*.scss|*.html|*.yml|*.yaml)
    command -v prettier >/dev/null && prettier --write "$file_path"
    ;;
esac
