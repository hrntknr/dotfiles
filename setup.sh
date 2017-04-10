#!/bin/sh

DOT_FILES=(
  .atom/config.cson
  .atom/init.coffee
  .atom/keymap.cson
  .atom/snippets.cson
  .atom/styles.less
  .vimrc
  .tmux.conf
  .zshrc
)

apm install --packages-file packages.list

for file in ${DOT_FILES[@]}
do
  ln -s $HOME/git/dotfiles/$file $HOME/$file
done
