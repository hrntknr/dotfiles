#!/bin/bash
set -uo pipefail

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
    case "$file" in
    *.json.d/* | *.jsonc.d/*)
      # *.json.d / *.jsonc.d fragments are merged by merge_json_configs
      continue
      ;;
    esac
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

function read_json_input {
  # $1: source file (JSON or JSONC). Echoes a temp path holding strict JSON, or returns 1.
  # Normalizes JSONC (comments, trailing commas) with the json5 CLI via JSON5_CMD.
  local src="$1"
  local tmp
  if [ "${#JSON5_CMD[@]}" -eq 0 ]; then
    return 1
  fi
  tmp=$(mktemp)
  if ! "${JSON5_CMD[@]}" "$src" >"$tmp" 2>/dev/null || ! jq -e . "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    return 1
  fi
  echo "$tmp"
}

function merge_json_config {
  local base="$1"
  local dir="$2"
  local file target f name tmp stripped
  local inputs=()
  local frags=()
  local tmps=()

  file="${dir#$base/}"
  file="${file%.d}"
  target="$basedir/$file"

  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    if [[ "$name" == *.sops ]]; then
      if ! type sops >/dev/null 2>&1; then
        echo "Skip $f"
        continue
      fi
      tmp=$(mktemp)
      if sops decrypt --input-type binary --output-type binary --output "$tmp" "$f" >/dev/null 2>&1; then
        tmps+=("$tmp")
        name="${name%.sops}"
        f="$tmp"
      else
        rm -f "$tmp"
        echo "Skip $f"
        continue
      fi
    fi
    case "$name" in
    *.darwin)
      [ "$(uname)" = "Darwin" ] || continue
      name="${name%.darwin}"
      ;;
    *.linux)
      [ "$(uname)" = "Linux" ] || continue
      name="${name%.linux}"
      ;;
    esac
    case "$name" in
    *.json | *.jsonc)
      stripped=$(read_json_input "$f")
      if [ -n "$stripped" ]; then
        frags+=("$stripped")
      else
        echo "Skip merge for $file (invalid JSON/JSONC: $f)"
      fi
      ;;
    esac
  done

  if [ "${#frags[@]}" -eq 0 ]; then
    rm -f ${tmps[@]+"${tmps[@]}"}
    return 0
  fi

  if [ -f "$target" ]; then
    stripped=$(read_json_input "$target")
    if [ -n "$stripped" ]; then
      inputs+=("$stripped")
    else
      echo "Warning: $target is not valid JSON/JSONC, replacing with merged fragments"
    fi
  fi

  tmp=$(mktemp)
  if jq -s '
    def merged($a; $b):
      if ($a|type) == "object" and ($b|type) == "object" then
        reduce ($b|keys_unsorted[]) as $k ($a; .[$k] = if $a|has($k) then merged($a[$k]; $b[$k]) else $b[$k] end)
      elif ($a|type) == "array" and ($b|type) == "array" then
        reduce ($b[]) as $x ($a; if any(.[]; . == $x) then . else . + [$x] end)
      else
        $b
      end;
    reduce .[] as $item ({}; merged(.; $item))
  ' ${inputs[@]+"${inputs[@]}"} "${frags[@]}" >"$tmp"; then
    mkdir -p "$(dirname "$target")"
    cat "$tmp" >"$target"
    echo "Merged $file"
  else
    echo "Skip merge for $file (jq failed)"
  fi
  rm -f "$tmp"
  rm -f ${tmps[@]+"${tmps[@]}"}
}

function merge_json_configs {
  local base="$cur/$1"
  local mise_bin
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found, skip JSON merges"
    return 0
  fi
  JSON5_CMD=()
  if command -v json5 >/dev/null 2>&1 && json5 --help >/dev/null 2>&1; then
    JSON5_CMD=(json5)
  else
    for mise_bin in "$HOME/.local/bin/mise" "$(realpath "$basedir")/.local/bin/mise"; do
      [ -x "$mise_bin" ] || continue
      if "$mise_bin" x npm:json5 -- true >/dev/null 2>&1; then
        JSON5_CMD=("$mise_bin" x npm:json5 -- json5)
        break
      fi
    done
  fi
  if [ "${#JSON5_CMD[@]}" -eq 0 ]; then
    echo "json5 not found (mise use -g npm:json5), skip JSON merges"
    return 0
  fi
  find -L "$base" \( -name '*.json.d' -o -name '*.jsonc.d' \) -type d -print0 |
    while IFS= read -r -d '' dir; do
      merge_json_config "$base" "$dir"
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

    "$mise_bin" install -y -C "$HOME"
    "$mise_bin" cache clear -y -C "$HOME"
  )
}

function setup_uv {
  local home
  home="$(realpath "$basedir")"

  (
    export HOME="$home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"

    if [ ! -x "$HOME/.local/bin/uv" ]; then
      mkdir -p "$HOME/.local/bin"
      curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR="$HOME/.local/bin" sh
    fi
  )
}

setup_mise

if [ "$skip_mise" -eq 0 ]; then
  setup_uv
  setup_mise_tools
fi

merge_json_configs files

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git_clone_https https://github.com/zsh-users/zsh-autosuggestions "$basedir/.zsh/zsh-autosuggestions"
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git_clone_https https://github.com/zsh-users/zsh-syntax-highlighting "$basedir/.zsh/zsh-syntax-highlighting"
fi
