#!/bin/sh

CD=$(cd $(dirname $0) && pwd)

case ${OSTYPE} in
  darwin*)
    if [ -x "'which brew'" ]; then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    PM_INSTALL="brew install"
    ;;
  linux*)
    if [ -x "'which apt'" ]; then
      PM_INSTALL="apt install"
    elif [ -x "'which dnf'" ]; then
      PM_INSTALL="dnf install"
    elif [ -x "'which yum'" ]; then
      PM_INSTALL="yum install"
    fi
    ;;
esac

for OPT in "$@"
do
  case $OPT in
    '-zsh' )
      FLAG_ZSH=1
      ;;
    '-atom' )
      FLAG_ATOM=1
      ;;
    '-vim' )
      FLAG_VIM=1
      ;;
  esac
  shift
done

if [ "$FLAG_ZSH" ]; then
  ln -s $CD/.zshrc $HOME/.zshrc
  ln -s $CD/.zprofile $HOME/.zprofile
fi

if [ "$FLAG_ATOM" ]; then
  apm install --packages-file packages.list
  ln -s $CD/.atom/config.cson $HOME/.atom/config.cson
  ln -s $CD/.atom/init.coffee $HOME/.atom/init.coffee
  ln -s $CD/.atom/keymap.cson $HOME/.atom/keymap.cson
  ln -s $CD/.atom/snippets.cson $HOME/.atom/snippets.cson
  ln -s $CD/.atom/styles.less $HOME/.atom/styles.less
fi

if [ "$FLAG_VIM" ]; then
  ln -s $CD/.vimrc $HOME/.vimrc
fi
