#!/bin/bash
set -eu
cd $(dirname $0)

function copyfile {
  file=$1
  srcFile=$(basename "$file")
  dstFile="$HOME/${srcFile//@//}"
  echo "copy src:$srcFile dst:$dstFile"
  if [ ! -d $(dirname "$dstFile") ]; then
    mkdir -p $(dirname "$dstFile")
  fi
  cp "files/$srcFile" "$dstFile"
}

export -f copyfile
find files -maxdepth 1 -type f -exec bash -c 'copyfile "$0"' {} \;

if [ -f "$HOME/.config/nvim/init.vim" ]; then
  rm "$HOME/.config/nvim/init.vim"
fi

if [ ! -e "$HOME/.zsh/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
fi
