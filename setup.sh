#!/bin/bash
set -euo pipefail

skip_mise=0
basedir=$HOME
basedir_args=()

function usage {
  echo "Usage: $0 [--skip-mise] [basedir]"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --skip-mise)
    skip_mise=1
    ;;
  -*)
    usage
    ;;
  *)
    basedir_args+=("${1%/}")
    ;;
  esac
  shift
done

if [ "${#basedir_args[@]}" -gt 1 ]; then
  usage
fi

if [ "${#basedir_args[@]}" -eq 1 ]; then
  basedir="${basedir_args[0]}"
  if [ ! -d "$basedir" ]; then
    mkdir -p "$basedir"
  fi
  cat <<EOS >"$basedir/zsh"
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
  chmod +x "$basedir/zsh"
fi

cur=$(dirname $0)

function should_install_file {
  local name
  name=$(basename "$1")
  name=${name%.sops}
  case "$name" in
  *.darwin)
    [ "$(uname)" = "Darwin" ]
    ;;
  *.linux)
    [ "$(uname)" = "Linux" ]
    ;;
  *)
    true
    ;;
  esac
}

function install_file {
  local file="$1"
  local src="$2"
  local target="$basedir/$file"
  local dir
  local name
  dir=$(dirname "$target")
  name=$(basename "$file")
  name=${name%.sops}
  case "$name" in
  *.darwin)
    if [ "$(uname)" != "Darwin" ]; then
      return
    fi
    name=${name%.darwin}
    ;;
  *.linux)
    if [ "$(uname)" != "Linux" ]; then
      return
    fi
    name=${name%.linux}
    ;;
  esac
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
  cp -v "$src" "$dir/$name"
}

function setup_files {
  find -L "$cur/$1" -type f -print0 | while IFS= read -r -d '' path; do
    local file
    local tmp
    file="${path#$cur/$1/}"
    if ! should_install_file "$file"; then
      continue
    fi
    if [[ "$file" == *.sops ]]; then
      if ! type sops >/dev/null 2>&1; then
        echo "Skip $file"
        continue
      fi
      tmp=$(mktemp)
      if sops decrypt --input-type binary --output-type binary --output "$tmp" "$path" >/dev/null 2>&1; then
        install_file "$file" "$tmp"
      else
        echo "Skip $file"
      fi
      rm -f "$tmp"
    else
      install_file "$file" "$path"
    fi
  done
}

setup_files files

function git_clone_https {
  local url="$1"
  local dst="$2"

  GIT_CONFIG_GLOBAL=/dev/null git clone "$url" "$dst"
}

function setup_mise {
  local home
  local mise_bin
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
  )
}

function setup_mise_tools {
  local github_token
  local home
  local mise_bin
  home="$(realpath "$basedir")"

  (
    export HOME="$home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"

    mise_bin="$HOME/.local/bin/mise"

    if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && github_token="$(gh auth token 2>/dev/null)"; then
      export GITHUB_TOKEN="$github_token"
    fi

    MISE_OFFLINE=0 "$mise_bin" install -y -C "$HOME"
    "$mise_bin" cache clear -y -C "$HOME"
  )
}

setup_mise

if [ "$skip_mise" -eq 0 ]; then
  setup_mise_tools
fi

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git_clone_https https://github.com/zsh-users/zsh-autosuggestions "$basedir/.zsh/zsh-autosuggestions"
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git_clone_https https://github.com/zsh-users/zsh-syntax-highlighting "$basedir/.zsh/zsh-syntax-highlighting"
fi
