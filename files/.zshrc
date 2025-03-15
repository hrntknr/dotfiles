ZDOTDIR=${ZDOTDIR:-$HOME}

export GPG_TTY=$(tty)

if [ -e "$ZDOTDIR/.zshrc.local" ]; then
  . "$ZDOTDIR/.zshrc.local"
fi

if [ -e "$ZDOTDIR/.zsh/functions" ]; then
  FPATH="$ZDOTDIR/.zsh/functions:$FPATH"
fi

if [ ! -e "$ZDOTDIR/.local" ]; then
  mkdir $ZDOTDIR/.local
fi

if [ -z "$SSH_AGENT_ENABLED" -a -e "/proc/$PPID/cmdline" ]; then
  if [[ ! $(cat /proc/$PPID/cmdline) =~ "sshd.+" ]]; then
    SSH_AGENT_ENABLED=${SSH_AGENT_ENABLED:-1}
  fi
fi
if [ "$SSH_AGENT_ENABLED" = "1" ]; then
  env_agent=$ZDOTDIR/.local/ssh-agent.env
  SSH_AGENT_ARGS=""
  if [ -n "$SSH_AGENT_TIMEOUT" ]; then
    SSH_AGENT_ARGS="-t $SSH_AGENT_TIMEOUT"
  fi
  if ! pgrep ssh-agent -U $USER &>/dev/null; then
    sh -c "ssh-agent -s $SSH_AGENT_ARGS > $env_agent"
  fi
  if [ -e "$env_agent" ]; then
    source $env_agent &>/dev/null
  fi
fi

if [ -z "$GPG_AGENT_ENABLED" -a -e "/proc/$PPID/cmdline" ]; then
  if [[ ! $(cat /proc/$PPID/cmdline) =~ "sshd.+" ]]; then
    GPG_AGENT_ENABLED=${GPG_AGENT_ENABLED:-1}
  fi
fi
if [ "$GPG_AGENT_ENABLED" = "1" ]; then
  GPG_AGENT_ARGS=""
  if [ -n "$GPG_AGENT_TIMEOUT" ]; then
    GPG_AGENT_ARGS="--default-cache-ttl $GPG_AGENT_TIMEOUT"
  fi
  if ! pgrep gpg-agent -U $USER &>/dev/null; then
    sh -c "gpg-agent -q --daemon $GPG_AGENT_ARGS"
  fi
fi

if [ -e "$ZDOTDIR/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  . "$ZDOTDIR/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -e "$ZDOTDIR/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  . "$ZDOTDIR/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

gitStatus() {
  local branch_name st branch_status

  if [ ! -e  ".git" ]; then
    return
  fi
  branch_name=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
  st=`git status 2> /dev/null`
  if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
    branch_status="\e[38;5;2m"
  elif [[ -n `echo "$st" | grep "^Untracked files"` ]]; then
    branch_status="\e[38;5;1m?"
  elif [[ -n `echo "$st" | grep "^Changes not staged for commit"` ]]; then
    branch_status="\e[38;5;1m+"
  elif [[ -n `echo "$st" | grep "^Changes to be committed"` ]]; then
    branch_status="\e[38;5;3m!"
  elif [[ -n `echo "$st" | grep "^rebase in progress"` ]]; then
    echo "\e[38;5;1m!(no branch)"
    return
  else
    branch_status="\e[38;5;4m"
  fi
  echo "${branch_status}[$branch_name]\e[m"
}

ignore() {
  curl -f https://raw.githubusercontent.com/github/gitignore/master/$(echo $1|awk '{print toupper(substr($1,1,1))substr($1,2)}').gitignore >> .gitignore
}

spwd() {
  if [[ $PWD == $HOME ]]; then
    prefix="~"
  elif [[ $PWD == $HOME* ]]; then
    prefix="~/"
  else
    prefix="/"
  fi
  path="${PWD/$HOME/}"
  paths=(${(s:/:)path})
  if [ ${#paths[@]} = 0 ] ;then
    echo $prefix
    return
  fi
  exclude_last=(${paths:0:-1})
  cur_short_path=''
  for cur_dir in $exclude_last; do
    cur_short_path+="${cur_dir:0:1}/"
  done
  cur_short_path+="${paths[-1]}"

  echo $prefix$cur_short_path
}

precmd() {
  if [ -z "$SHELL_COLOR" ];then
    if type md5sum > /dev/null 2>&1; then
      local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5sum|md5sum|cut -c1-2))"'m'
    elif type md5 > /dev/null 2>&1; then
      local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5|md5|cut -c1-2))"'m'
    else
      local HOSTCOLOR=$'\e[0m'
    fi
  else
    local HOSTCOLOR=$'\e[38;05;'"$SHELL_COLOR"'m'
  fi
  print -P "\n%n@$HOSTCOLOR$(hostname)\e[m $(spwd) $(gitStatus)"
}

preexec() {
}

peco-history-selection() {
  case ${OSTYPE} in
    darwin*)
      BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
      ;;
    linux*)
      BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
      ;;
  esac
  CURSOR=$#BUFFER
  zle reset-prompt
}

if type peco > /dev/null 2>&1; then
  zle -N peco-history-selection
  bindkey '^R' peco-history-selection
fi

export PROMPT="%(?,,%F{red}%?%f)> %F{green}$%f "
export PROMPT2="> "
export HISTFILE="${ZDOTDIR}/.zsh_history"
export HISTSIZE="1000000"
export SAVEHIST="1000000"
export KEYTIMEOUT=1
setopt share_history
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

alias l='ls -ltrG'
alias ls='ls -G'
alias la='ls -laG'
alias ll='ls -lG'
alias mdig='dig @224.0.0.251 -p 5353'
alias mdig6='dig @ff02::fb -p 5353'
alias tmp='cd $(mktemp -d)'
alias man='env LANGUAGE=ja_JP.utf8 man'
alias timestamp="date +%Y%m%d%H%M%S"
alias lower="tr '[:upper:]' '[:lower:]'"
alias upper="tr '[:lower:]' '[:upper:]'"
alias ga='gh run watch $(gh run list | grep -i "$1" | head -n1 | awk "{print \$7}")'

# https://github.com/neovim/neovim/releases/
NVIM_VERSION=stable
# https://nodejs.org/en
NODE_VERSION=v20.9.0
# https://github.com/peco/peco/releases/
PECO_VERSION=v0.5.11

install_nvim() {
  case "${OSTYPE},$(uname -m)" in
    darwin*,*)
      TARGET=macos
      ;;
    linux*,x86_64)
      TARGET=linux64
      ;;
    *)
      echo "Unknown OS"
      return
      ;;
  esac
  curl -fsSL https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-$TARGET.tar.gz | tar xz --strip-components=1 -C ~/.local/
}

install_node() {
  case "${OSTYPE},$(uname -m)" in
    darwin*,*)
      TARGET=darwin-x64
      ;;
    linux*,x86_64)
      TARGET=linux-x64
      ;;
    *)
      echo "Unknown OS"
      return
      ;;
  esac
  curl -fsSL https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$TARGET.tar.gz | tar xz --strip-components=1 -C ~/.local/
}

install_peco() {
  case "${OSTYPE},$(uname -m)" in
    darwin*,x86_64)
      TARGET=darwin_amd64
      EXT=zip
      ;;
    darwin*,arm64)
      TARGET=darwin_arm64
      EXT=zip
      ;;
    linux*,x86_64)
      TARGET=linux_amd64
      EXT=tar.gz
      ;;
    *)
      echo "Unknown OS"
      return
      ;;
  esac
  tmp=$(mktemp -d)
  curl -fsSL https://github.com/peco/peco/releases/download/$PECO_VERSION/peco_$TARGET.$EXT -o $tmp/peco.$EXT
  case $EXT in
    zip)
      unzip -j $tmp/peco.$EXT -d $tmp >/dev/null
      ;;
    tar.gz)
      tar xf $tmp/peco.$EXT --strip-components=1 -C $tmp
      ;;
  esac
  cp $tmp/peco ~/.local/bin/
}

install() {
  install_node
  install_nvim
  install_peco
}

if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

autoload -Uz compinit
compinit

setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
setopt extended_glob
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

function _ssh {
  hosts=$(register_ssh "$HOME/.ssh/config" | uniq | sort | tr '\n' ' ')
  for host (${(z)hosts}) compadd $host
}

function register_ssh {
  if [ ! -f "$1" ]; then
    return
  fi
  echo "$(fgrep 'Host ' $1 | awk '{print $2}' | sort)";
  includes="$(fgrep 'Include ' $1 | awk '{print $2}' | xargs -I % sh -c 'echo %' | tr '\n' ' ')";
  for include (${(z)includes}) {
    cd "$(dirname $1)"
    cd "$(dirname $include)"
    register_ssh "$(pwd)/$(basename $include)"
  }
}

function ssh-kill {
  mux=$(ps aux | grep 'ssh[:]' | tr -s ' ' | cut -d ' ' -f 12 | xargs basename | sort | peco)
  if [ -z "$mux" ]; then
    return
  fi
  ps aux | grep "ssh[:]" | grep "$mux" | tr -s ' ' | cut -d ' ' -f 2 | xargs kill
}

function nat64 {
  echo $1 | sed -e "s/\./ /g" | xargs printf "64:ff9b::%02x%02x:%02x%02x\n"
}

case ${OSTYPE} in
  darwin*)
    alias netstat-lntp='lsof -nP -iTCP -sTCP:LISTEN'
    ;;
  linux*)
    alias open='xdg-open'
    ;;
esac

if ! type copy > /dev/null 2>&1; then
  function copy {
    printf "\033]52;;$(cat|base64)\033\\"
  }
fi

if type kubectl > /dev/null 2>&1; then
  alias k=kubectl
  alias kns='kubectl config set-context $(kubectl config current-context) --namespace'
  alias knet='kubectl debug -it --image nicolaka/netshoot'
  function krl {
    if [ -z "$1" ]; then
      echo "Usage: krl <label>"
      return
    fi
    kubectl get deployment -l $1 -o "jsonpath={.items[*].metadata.name}" | xargs -n1 kubectl rollout restart deployment
  }
fi

if type openstack > /dev/null 2>&1; then
  alias os=openstack
fi
