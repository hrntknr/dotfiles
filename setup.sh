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
  find "$cur/$1" -type f -print0 | while IFS= read -r -d '' file; do
    file="${file#$cur/$1/}"
    target="$basedir/$file"
    dir=$(dirname "$target")
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir"
    fi
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

function download_files {
  url="$1"
  dst="$2"
  pat="$3"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  f="$tmp/${url##*/}"

  curl -fsSL "$url" -o "$f"

  case "$f" in
    *.zip)    unzip -q "$f" -d "$tmp" ;;
    *.tar.gz|*.tgz) tar -xzf "$f" -C "$tmp" ;;
    *) echo "unsupported: $f" >&2; return 1 ;;
  esac
  mkdir -p "$dst"
  for src in "$tmp"/$pat; do
    if [ ! -e "$src" ]; then
      continue
    fi
    target="$dst/$(basename "$src")"
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

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m | tr '[:upper:]' '[:lower:]')"
case "$platform-$arch" in
darwin-arm64)
  if [ ! -f "$basedir/.local/bin/fzf" ]; then
    download_files \
      https://github.com/junegunn/fzf/releases/download/v0.67.0/fzf-0.67.0-darwin_arm64.tar.gz \
      "$basedir/.local/bin" \
      fzf
  fi
  if [ ! -f "$basedir/.local/bin/starship" ]; then
    download_files \
      https://github.com/starship/starship/releases/latest/download/starship-aarch64-apple-darwin.tar.gz \
      "$basedir/.local/bin" \
      starship
  fi
  if [ ! -f "$basedir/.local/bin/nvim" ]; then
    download_files \
      https://github.com/neovim/neovim/releases/latest/download/nvim-macos-arm64.tar.gz \
      "$basedir/.local" \
      'nvim-macos-arm64/*'
  fi
  if [ ! -f "$basedir/.local/bin/tmux" ]; then
    download_files \
      https://github.com/tmux/tmux-builds/releases/latest/download/tmux-3.6a-macos-arm64.tar.gz \
      "$basedir/.local/bin" \
      tmux
  fi
  if [ ! -f "$basedir/.local/bin/ghq" ]; then
    download_files \
      https://github.com/x-motemen/ghq/releases/latest/download/ghq_darwin_arm64.zip \
      "$basedir/.local/bin" \
      ghq_darwin_arm64/ghq
  fi
  ;;
linux-x86_64)
  if [ ! -f "$basedir/.local/bin/fzf" ]; then
    download_files \
      https://github.com/junegunn/fzf/releases/download/v0.67.0/fzf-0.67.0-linux_amd64.tar.gz \
      "$basedir/.local/bin" \
      fzf
  fi
  if [ ! -f "$basedir/.local/bin/starship" ]; then
    download_files \
      https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz \
      "$basedir/.local/bin" \
      starship
  fi
  if [ ! -f "$basedir/.local/bin/nvim" ]; then
    download_files \
      https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      "$basedir/.local" \
      'nvim-linux-x86_64/*'
  fi
  if [ ! -f "$basedir/.local/bin/tmux" ]; then
    download_files \
      https://github.com/tmux/tmux-builds/releases/latest/download/tmux-3.6a-linux-x86_64.tar.gz \
      "$basedir/.local/bin" \
      tmux
  fi
  if [ ! -f "$basedir/.local/bin/ghq" ]; then
    download_files \
      https://github.com/x-motemen/ghq/releases/latest/download/ghq_linux_amd64.zip \
      "$basedir/.local/bin" \
      ghq_linux_amd64/ghq
  fi
  ;;
*)
  echo "Unsupported platform: $platform-$arch"
  ;;
esac

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $basedir/.zsh/zsh-autosuggestions
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $basedir/.zsh/zsh-syntax-highlighting
fi
