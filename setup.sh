#!/bin/bash
set -eu
cd $(dirname $0)

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

for file in $(find ./files -type f -printf '%P\n'); do
  target="$basedir/$file"
  dir=$(dirname "$target")
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
  cp -v "./files/$file" "$target"
done

if [ ! -e "$HOME/.zsh/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
fi
