#!/bin/bash

CD=$(cd $(dirname $0) && pwd)

function yes_or_no_select(){
  PS3=">"
  while true;do
    select answer in yes no;do
      case $answer in
        yes)
          return 0
          ;;
        no)
          return 1
          ;;
      esac
    done
  done
}

case ${OSTYPE} in
  darwin*)
    if [ ! "`type "brew"`" ]; then
      echo "Can't find Homebrew."
      echo "Install Homebrew?"
      if yes_or_no_select; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        FLAG_PM_ENABLE=1
        PM_INSTALL="brew install"
      fi
    else
      echo "Find Homebrew."
      FLAG_PM_ENABLE=1
      PM_INSTALL="brew install"
    fi
    ;;
  linux*)
    if type "apt"; then
      echo "Find apt."
      FLAG_PM_ENABLE=1
      PM_INSTALL="apt install"
    elif type "dnf"; then
      echo "Find dnf."
      FLAG_PM_ENABLE=1
      PM_INSTALL="dnf install"
    elif type "yum"; then
      echo "Find yum."
      FLAG_PM_ENABLE=1
      PM_INSTALL="yum install"
    fi
    ;;
esac
if [ "$FLAG_PM_ENABLE" ]; then
  echo "Install command: $PM_INSTALL"
else
  echo "Can't find package manager."
fi

if [ ! "`type "git"`" ] && [ "$FLAG_PM_ENABLE" ]; then
  echo "Can't find git."
  echo "Install git?"
  if yes_or_no_select; then
    eval "$PM_INSTALL git"
  fi
fi

if [ ! "`type "nvm"`" ] && [ ! -e "$HOME/.nvm" ]; then
  echo "Can't find nvm."
  echo "Install nvm?"
  if yes_or_no_select; then
    git clone git://github.com/creationix/nvm.git ~/.nvm
  fi
fi

function config_zsh(){
  echo "Config zsh?"
  if yes_or_no_select; then
    ln -s $CD/.zshrc $HOME/.zshrc
    ln -s $CD/.zprofile $HOME/.zprofile
  fi
}

if [ ! "`type "zsh"`" ] && [ "$FLAG_PM_ENABLE" ]; then
  echo "Can't find zsh."
  echo "Install zsh?"
  if yes_or_no_select; then
    eval "$PM_INSTALL zsh"
    config_zsh
  fi
else
  config_zsh
fi

function config_vim(){
  echo "Config vim?"
  if yes_or_no_select; then
    ln -s $CD/.vimrc $HOME/.vimrc
  fi
}

if [ ! "`type "vim"`" ] && [ "$FLAG_PM_ENABLE" ]; then
  echo "Can't find vim."
  echo "Install vim?"
  if yes_or_no_select; then
    eval "$PM_INSTALL vim"
    config_vim
  fi
else
  config_vim
fi

function config_tmux(){
  echo "Config tmux?"
  if yes_or_no_select; then
    ln -s $CD/.tmux.conf $HOME/.tmux.conf
  fi
}

if [ ! "`type "tmux"`" ] && [ "$FLAG_PM_ENABLE" ]; then
  echo "Can't find tmux."
  echo "Install tmux?"
  if yes_or_no_select; then
    eval "$PM_INSTALL tmux"
    config_tmux
  fi
else
  config_tmux
fi

echo "Config eslint?"
if yes_or_no_select; then
  ln -s $CD/.eslintrc.json $HOME/.eslintrc.json
fi
