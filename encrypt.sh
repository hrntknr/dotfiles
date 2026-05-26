#!/bin/bash
set -euo pipefail

src_dir="${1:-.decrypted}"
out_dir="${2:-files}"

command -v sops >/dev/null || {
  echo "sops not found" >&2
  exit 1
}

if [ ! -d "$src_dir" ]; then
  echo "source directory not found: $src_dir" >&2
  exit 1
fi

found=0
while IFS= read -r -d '' src; do
  found=1
  rel="${src#$src_dir/}"
  dest="$out_dir/$rel.sops"
  mkdir -p "$(dirname "$dest")"
  sops encrypt \
    --filename-override "$dest" \
    --input-type binary \
    --output-type binary \
    --output "$dest" \
    "$src"
  echo "$src -> $dest"
done < <(find "$src_dir" -type f -print0 | sort -z)

if [ "$found" -eq 0 ]; then
  echo "no files found under $src_dir"
fi
