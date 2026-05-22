#!/bin/bash
set -eu

case "$#" in
0)
  basedir=$HOME
  ;;
1)
  basedir=${1%/}
  if [ ! -d "$basedir" ]; then
    mkdir -p "$basedir"
  fi
  cat <<EOS >$basedir/zsh
#!/bin/bash
export HOME=$(realpath $basedir)
export ZDOTDIR=\$HOME
export XDG_CONFIG_HOME="\$HOME/.config"
export XDG_DATA_HOME="\$HOME/.local/share"
export XDG_CACHE_HOME="\$HOME/.cache"
export XDG_STATE_HOME="\$HOME/.local/state"
exec zsh -l
EOS
  chmod +x $basedir/zsh
  ;;
*)
  echo "Usage: $0 [basedir]"
  exit 1
  ;;
esac

cur=$(dirname $0)

function setup_files {
  find -L "$cur/$1" -type f -print0 | while IFS= read -r -d '' file; do
    file="${file#$cur/$1/}"
    target="$basedir/$file"
    dir=$(dirname "$target")
    name=$(basename "$file")
    case "$name" in
    *.darwin)
      if [ "$(uname)" != "Darwin" ]; then
        continue
      fi
      name=${name%.darwin}
      ;;
    *.linux)
      if [ "$(uname)" != "Linux" ]; then
        continue
      fi
      name=${name%.linux}
      ;;
    esac
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir"
    fi
    cp -v "$cur/$1/$file" "$dir/$name"
  done
}

setup_files files
if type git-crypt >/dev/null 2>&1; then
  set +e
  (
    set -e
    cd $cur
    git crypt unlock
  )
  if [ $? -eq 0 ]; then
    set -e
    setup_files files-crypt
  else
    echo "Skip files-crypt"
  fi
fi

function extract_zip {
  local file="$1"
  local dst="$2"

  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$file" -d "$dst"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m zipfile -e "$file" "$dst"
  else
    echo "unzip or python3 is required to extract: $file" >&2
    return 1
  fi
}

function download_files {
  local url="$1"
  local dst="$2"
  local pat="$3"
  local tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  local f="$tmp/${url##*/}"

  curl -fsSL "$url" -o "$f"

  case "$f" in
    *.zip)    extract_zip "$f" "$tmp" ;;
    *.tar.gz|*.tgz) tar -xzf "$f" -C "$tmp" ;;
    *) echo "unsupported: $f" >&2; return 1 ;;
  esac
  mkdir -p "$dst"
  local src
  for src in "$tmp"/$pat; do
    if [ ! -e "$src" ]; then
      continue
    fi
    local target="$dst/$(basename "$src")"
    echo "Installing $target"
    if [ -d "$src" ]; then
      mkdir -p "$target"
      cp -R "$src"/. "$target"/
    else
      mkdir -p "$(dirname "$target")"
      cp -f "$src" "$target"
    fi
  done
}

function download_file_as {
  local url="$1"
  local dst="$2"
  local pat="$3"
  local tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  local f="$tmp/${url##*/}"

  curl -fsSL "$url" -o "$f"

  case "$f" in
    *.zip)    extract_zip "$f" "$tmp" ;;
    *.tar.gz|*.tgz) tar -xzf "$f" -C "$tmp" ;;
    *) echo "unsupported: $f" >&2; return 1 ;;
  esac
  mkdir -p "$(dirname "$dst")"
  cp -f "$tmp/$pat" "$dst"
  chmod +x "$dst"
}

function github_latest_download_url {
  local repo="$1"
  local pattern="$2"

  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
    python3 -c 'import json, sys
import re
pattern = re.compile(sys.argv[1])
for asset in json.load(sys.stdin)["assets"]:
    if pattern.fullmatch(asset["name"]):
        print(asset["browser_download_url"])
        break
else:
    raise SystemExit(f"asset not found: {pattern.pattern}")' "$pattern"
}

function git_clone_https {
  local url="$1"
  local dst="$2"

  GIT_CONFIG_GLOBAL=/dev/null git clone "$url" "$dst"
}

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m | tr '[:upper:]' '[:lower:]')"
case "$platform-$arch" in
darwin-arm64)
  if [ ! -f "$basedir/.local/bin/zsh-static" ]; then
    download_file_as \
      "$(github_latest_download_url romkatv/zsh-bin 'zsh-[0-9.]+-darwin-arm64\.tar\.gz')" \
      "$basedir/.local/bin/zsh-static" \
      bin/zsh
  fi
  if [ ! -f "$basedir/.local/bin/fzf" ]; then
    download_files \
      "$(github_latest_download_url junegunn/fzf 'fzf-[0-9.]+-darwin_arm64\.tar\.gz')" \
      "$basedir/.local/bin" \
      fzf
  fi
  if [ ! -f "$basedir/.local/bin/nvim" ]; then
    download_files \
      https://github.com/neovim/neovim/releases/latest/download/nvim-macos-arm64.tar.gz \
      "$basedir/.local" \
      'nvim-macos-arm64/*'
  fi
  if [ ! -f "$basedir/.local/bin/tmux" ]; then
    download_files \
      "$(github_latest_download_url tmux/tmux-builds 'tmux-[0-9][0-9a-z.]*-macos-arm64\.tar\.gz')" \
      "$basedir/.local/bin" \
      tmux
  fi
  if [ ! -f "$basedir/.local/bin/ghq" ]; then
    download_files \
      https://github.com/x-motemen/ghq/releases/latest/download/ghq_darwin_arm64.zip \
      "$basedir/.local/bin" \
      ghq_darwin_arm64/ghq
  fi
  if [ ! -f "$basedir/.local/bin/deno" ]; then
    download_files \
      https://github.com/denoland/deno/releases/latest/download/deno-aarch64-apple-darwin.zip \
      "$basedir/.local/bin" \
      deno
  fi
  if [ ! -f "$basedir/.local/bin/yq" ]; then
    mkdir -p "$basedir/.local/bin"
    curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_arm64 \
      -o "$basedir/.local/bin/yq"
    chmod +x "$basedir/.local/bin/yq"
  fi
  if [ ! -f "$basedir/.local/bin/sbx" ]; then
    download_files \
      https://github.com/hrntknr/sbx/releases/latest/download/sbx_darwin_arm64.zip \
      "$basedir/.local/bin" \
      sbx_darwin_arm64/sbx
  fi
  if [ ! -f "$basedir/.local/bin/k9s" ]; then
    download_files \
      https://github.com/derailed/k9s/releases/latest/download/k9s_Darwin_arm64.tar.gz \
      "$basedir/.local/bin" \
      k9s
  fi
  ;;
linux-x86_64)
  if [ ! -f "$basedir/.local/bin/zsh-static" ]; then
    download_file_as \
      "$(github_latest_download_url romkatv/zsh-bin 'zsh-[0-9.]+-linux-x86_64\.tar\.gz')" \
      "$basedir/.local/bin/zsh-static" \
      bin/zsh
  fi
  if [ ! -f "$basedir/.local/bin/fzf" ]; then
    download_files \
      "$(github_latest_download_url junegunn/fzf 'fzf-[0-9.]+-linux_amd64\.tar\.gz')" \
      "$basedir/.local/bin" \
      fzf
  fi
  if [ ! -f "$basedir/.local/bin/nvim" ]; then
    download_files \
      https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      "$basedir/.local" \
      'nvim-linux-x86_64/*'
  fi
  if [ ! -f "$basedir/.local/bin/tmux" ]; then
    download_files \
      "$(github_latest_download_url tmux/tmux-builds 'tmux-[0-9][0-9a-z.]*-linux-x86_64\.tar\.gz')" \
      "$basedir/.local/bin" \
      tmux
  fi
  if [ ! -f "$basedir/.local/bin/ghq" ]; then
    download_files \
      https://github.com/x-motemen/ghq/releases/latest/download/ghq_linux_amd64.zip \
      "$basedir/.local/bin" \
      ghq_linux_amd64/ghq
  fi
  if [ ! -f "$basedir/.local/bin/deno" ]; then
    download_files \
    https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip \
      "$basedir/.local/bin" \
      deno
  fi
  if [ ! -f "$basedir/.local/bin/yq" ]; then
    mkdir -p "$basedir/.local/bin"
    curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
      -o "$basedir/.local/bin/yq"
    chmod +x "$basedir/.local/bin/yq"
  fi
  if [ ! -f "$basedir/.local/bin/sbx" ]; then
    download_files \
      https://github.com/hrntknr/sbx/releases/latest/download/sbx_linux_amd64.tar.gz \
      "$basedir/.local/bin" \
      sbx_linux_amd64/sbx
  fi
  if [ ! -f "$basedir/.local/bin/k9s" ]; then
    download_files \
      https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz \
      "$basedir/.local/bin" \
      k9s
  fi
  ;;
*)
  echo "Unsupported platform: $platform-$arch"
  ;;
esac

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git_clone_https https://github.com/zsh-users/zsh-autosuggestions "$basedir/.zsh/zsh-autosuggestions"
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git_clone_https https://github.com/zsh-users/zsh-syntax-highlighting "$basedir/.zsh/zsh-syntax-highlighting"
fi
