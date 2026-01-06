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
ZDOTDIR=$(realpath $basedir) zsh
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

function setup_binaries {
  url="$1"; pat="$2"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  f="$tmp/${url##*/}"

  curl -fsSL "$url" -o "$f"

  case "$f" in
    *.zip)    unzip -q "$f" -d "$tmp" ;;
    *.tar.gz|*.tgz) tar -xzf "$f" -C "$tmp" ;;
    *) echo "unsupported: $f" >&2; return 1 ;;
  esac
  for src in "$tmp"/$pat; do
    [[ -f "$src" ]] || continue
    dst="$basedir/.local/bin/$(basename "$src")"
    echo "installing $dst"
    install -m 0755 "$src" "$dst"
  done
}

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m | tr '[:upper:]' '[:lower:]')"
case "$platform-$arch" in
darwin-arm64)
  setup_binaries \
    https://github.com/peco/peco/releases/latest/download/peco_darwin_arm64.zip \
    'peco_*/peco'
  setup_binaries \
    https://github.com/starship/starship/releases/latest/download/starship-aarch64-apple-darwin.tar.gz \
    starship
  ;;
linux-x86_64)
  setup_binaries \
    https://github.com/peco/peco/releases/latest/download/peco_linux_amd64.tar.gz \
    'peco_*/peco'
  setup_binaries \
    https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz \
    starship
  ;;
*)
  echo "Unsupported platform: $platform-$arch"
  exit 1
  ;;
esac

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $basedir/.zsh/zsh-autosuggestions
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $basedir/.zsh/zsh-syntax-highlighting
fi
