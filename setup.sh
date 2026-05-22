#!/bin/bash
set -euo pipefail

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
if [ -x "\$XDG_DATA_HOME/mise/shims/zsh" ]; then
  exec "\$XDG_DATA_HOME/mise/shims/zsh" -l
fi
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

function git_clone_https {
  local url="$1"
  local dst="$2"

  GIT_CONFIG_GLOBAL=/dev/null git clone "$url" "$dst"
}

function setup_mise_tools {
  local home
  home="$(realpath "$basedir")"

  (
    export HOME="$home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"

    mise_bin="$HOME/.local/bin/mise"
    if [ ! -x "$mise_bin" ]; then
      mkdir -p "$(dirname "$mise_bin")"
      curl -fsSL https://mise.run | MISE_INSTALL_PATH="$mise_bin" sh
    fi

    "$mise_bin" install -y -C "$HOME"
  )
}

setup_mise_tools

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git_clone_https https://github.com/zsh-users/zsh-autosuggestions "$basedir/.zsh/zsh-autosuggestions"
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git_clone_https https://github.com/zsh-users/zsh-syntax-highlighting "$basedir/.zsh/zsh-syntax-highlighting"
fi
