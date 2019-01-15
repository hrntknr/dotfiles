#!/bin/bash
set -eu
cd $(dirname $0)

USER="$(logname)"
SKIP_INSTALL=false
TMP=$(mktemp -d)
sudo -u $USER mkdir -p $TMP

while getopts u:sh OPT
do
  case $OPT in
    u)  USER=$OPTARG
        ;;
    s)  SKIP_INSTALL=true
        ;;
    h)  usage_exit
        ;;
    \?) usage_exit
        ;;
  esac
done

HOME_DIR=$(eval echo ~$USER)

function require_root() {
  if [ "$(whoami)" != "root" ] && (! "$SKIP_INSTALL"); then
    echo "Require root privilege"
    exit 1;
  fi
}

function usage_exit() {  
cat <<EOF
$(basename ${0})
Usage:
    $(basename ${0}) [command] [<options>]

Options:
    -u        set user(default: current user)
    -s        skip root command
    -h        print this
EOF
}

function setup_dein() {
  # TODO: update
  if ! [ -e "$HOME_DIR/.cache/dein" ]; then
    sudo -u $USER sh -c "curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > $TMP/dein_installer.sh"
    sudo -u $USER sh $TMP/dein_installer.sh $HOME_DIR/.cache/dein
  fi
}

function setup_dotfiles() {
  sudo -u $USER cp ./.zshrc $HOME_DIR/.zshrc
  sudo -u $USER cp ./.zprofile $HOME_DIR/.zprofile
  sudo -u $USER cp ./.vimrc $HOME_DIR/.vimrc
  sudo -u $USER cp ./.tmux.conf $HOME_DIR/.tmux.conf
  sudo -u $USER cp ./.eslintrc.js $HOME_DIR/.eslintrc.js
  sudo -u $USER cp ./.editorconfig $HOME_DIR/.editorconfig
  sudo -u $USER mkdir -p $HOME_DIR/.config/nvim
  sudo -u $USER cp ./.config@nvim@init.vim $HOME_DIR/.config/nvim/init.vim
  sudo -u $USER cp ./.config@nvim@dein-plugins.toml $HOME_DIR/.config/nvim/dein-plugins.toml
}

case $OSTYPE in
  darwin*)
    OS=$(uname -s)
    VER=$(uname -r)
    ;;
  linux*)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS=$NAME
      VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
      OS=$(lsb_release -si)
      VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
      . /etc/lsb-release
      OS=$DISTRIB_ID
      VER=$DISTRIB_RELEASE
    else
      OS=$(uname -s)
      VER=$(uname -r)
    fi
    ;;
esac

case $OS in
  Darwin)
    if ! "$SKIP_INSTALL"; then
      if ! type brew > /dev/null 2>&1; then
        sudo -u $USER sh -c '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
      fi

      will_install=()
      if ! type vim > /dev/null 2>&1; then
        will_install+=( "vim" )
      fi
      if ! type nvim > /dev/null 2>&1; then
        will_install+=( "neovim" )
      fi
      if ! type wget > /dev/null 2>&1; then
        will_install+=( "wget" )
      fi
      if [ ${#will_install[@]} != 0 ]; then
        sudo -u $USER brew install "${will_install[@]}"
      fi
    fi
    setup_dein
    setup_dotfiles
  ;;
  Ubuntu)
    require_root
    if ! "$SKIP_INSTALL"; then
      apt-get update
      apt-get install vim neovim

      will_install=()
      if ! type vim > /dev/null 2>&1; then
        will_install+=( "vim" )
      fi
      if ! type wget > /dev/null 2>&1; then
        will_install+=( "wget" )
      fi
      if [ ${#will_install[@]} != 0 ]; then
        apt-get install "${will_install[@]}"
      fi
    fi
    setup_dein
    setup_dotfiles
  ;;
  Linux)
    echo "not supported.(Linux)"
    exit 1
  ;;
  *)
    echo "not supported.(General)"
    exit 2
  ;;
esac
