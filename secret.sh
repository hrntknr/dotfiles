#!/bin/bash
set -euo pipefail

region="ap-northeast-1"
sops_age_key_path="$HOME/.config/sops/age/keys.txt"
if [[ "$(uname -s)" == "Darwin" ]]; then
  sops_age_key_path="$HOME/Library/Application Support/sops/age/keys.txt"
fi

targets=(
  "hrntknr_ed25519_sec.pem,$HOME/.ssh/hrntknr_ed25519_sec.pem,600"
  "sops_age_keys.txt,$sops_age_key_path,600"
)

command -v aws >/dev/null || { echo "aws cli not found" >&2; exit 1; }
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  aws login --region "$region"
fi

for t in "${targets[@]}"; do
  IFS=',' read -r src dest perm <<<"$t"
  mkdir -p "$(dirname "$dest")"
  aws secretsmanager get-secret-value \
    --region "$region" \
    --secret-id "$src" \
    --query SecretString \
    --output text >"$dest"
  chmod "$perm" "$dest"
done
