#!/bin/bash
set -euo pipefail

src_dir="${1:-files}"
out_dir="${2:-.decrypted}"

command -v sops >/dev/null || {
  echo "sops not found" >&2
  exit 1
}

if [ ! -d "$src_dir" ]; then
  echo "source directory not found: $src_dir" >&2
  exit 1
fi

mkdir -p "$out_dir"

found=0
while IFS= read -r -d '' src; do
  found=1
  rel="${src#$src_dir/}"
  dest="$out_dir/${rel%.sops}"
  mkdir -p "$(dirname "$dest")"
  sops decrypt --input-type binary --output-type binary --output "$dest" "$src"
  chmod 600 "$dest"
  echo "$src -> $dest"
done < <(find "$src_dir" -type f -name '*.sops' -print0 | sort -z)

if [ "$found" -eq 0 ]; then
  echo "no sops files found under $src_dir"
fi
