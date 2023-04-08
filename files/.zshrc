export GPG_TTY=$(tty)

if [ -e "$HOME/.zshrc.local" ]; then
  . "$HOME/.zshrc.local"
fi

if [ -e "$HOME/.zsh/functions" ]; then
  FPATH="$HOME/.zsh/functions:$FPATH"
fi

if [ ! -e "$HOME/.local" ]; then
  mkdir $HOME/.local
fi

if [ -e "/proc/$PPID/cmdline" ]; then
  if [[ ! $(cat /proc/$PPID/cmdline) =~ "sshd.+" ]]; then
    SSH_AGENT_ENABLED=${SSH_AGENT_ENABLED:-1}
  fi
fi
if [ -n "$SSH_AGENT_ENABLED" ]; then
  env_agent=$HOME/.local/ssh-agent.env
  SSH_AGENT_TIMEOUT=${SSH_AGENT_TIMEOUT:-"1h"}
  if ! pgrep ssh-agent -U $USER &>/dev/null; then
    ssh-agent -s -t $SSH_AGENT_TIMEOUT >$env_agent
  fi
  if [ -e "$env_agent" ]; then
    source $env_agent &>/dev/null
  fi
fi

if [ -e "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  . "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
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
  local RESULT=$?
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

  if [ ! -z "$SLACK_NOTIFY" ] || [ ! -z "$DISCORD_NOTIFY" ]; then
    if [ $TTYIDLE -gt 10  -a "$execflg" = true ]; then
      local title="$RESULT> $prev_command"
      if [ $RESULT -eq 0 ]; then
        local color="#00d000"
      else
        local color="#d00000"
      fi
      json=`cat << EOS
{
  "attachments": [
    {
      "color": "$color",
      "title": "$title",
      "mrkdwn_in": ["fields"],
      "fields": [
        {
          "title": "command",
          "value": "\\\`$prev_command\\\`",
          "short": false
        },
        {
          "title": "directory",
          "value": "\\\`$(pwd)\\\`",
          "short": false
        },
        {
          "title": "hostname",
          "value": "$(hostname)",
          "short": true
        },
        {
          "title": "user",
          "value": "$(whoami)",
          "short": true
        },
        {
          "title": "elapsed time",
          "value": "$TTYIDLE seconds",
          "short": true
        }
      ]
    }
  ]
}
EOS
`
      if [ ! -z "$SLACK_NOTIFY" ]; then
        curl -H 'Content-Type:application/json' -d $json $SLACK_NOTIFY
      fi
      if [ ! -z "$DISCORD_NOTIFY" ]; then
        curl -H 'Content-Type:application/json' -d $json "$DISCORD_NOTIFY/slack"
      fi
    fi
  fi
  execflg=false
}

preexec() {
  prev_executed_at=`date +%F\ %T`
  prev_command=$2
  execflg=true
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

export PROMPT="> %F{green}$%f "
export PROMPT2="> "
export HISTFILE="${HOME}/.zsh_history"
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

if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

if type code > /dev/null 2>&1; then
_code=code
code() {
  host=${1%%:*}
  dir=${1##*:}
  if [ "$host" = "$dir" ]; then
    command code $1
  else
    home=""
    if [ "$dir" = "" -o "${dir:0:1}" != "/" ]; then
      home="$(ssh $host pwd)/"
    fi
    command code --folder-uri "vscode-remote://ssh-remote+$host$home$dir"
  fi
}
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

function copy {
  printf "\033]52;;$(cat|base64)\033\\"
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

if type kubectl > /dev/null 2>&1; then
  alias k=kubectl
fi

if type openstack > /dev/null 2>&1; then
  alias os=openstack
fi
