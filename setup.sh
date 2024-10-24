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
for file in $(find $cur/files -type f); do
  file=${file#$cur/files/}
  target="$basedir/$file"
  dir=$(dirname "$target")
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
  cp -v "$cur/files/$file" "$target"
done

if [ ! -e "$basedir/.zsh/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $basedir/.zsh/zsh-autosuggestions
fi

if [ ! -e "$basedir/.zsh/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $basedir/.zsh/zsh-syntax-highlighting
fi
