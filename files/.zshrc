ZDOTDIR=${ZDOTDIR:-$HOME}

autoload -Uz add-zsh-hook

# zsh settings
export GPG_TTY=$(tty)
export HISTFILE="${ZDOTDIR}/.zsh_history"
export HISTSIZE=1000000
export SAVEHIST=1000000
export KEYTIMEOUT=1
setopt share_history
setopt hist_fcntl_lock
setopt hist_ignore_dups
setopt hist_ignore_space
setopt nolistbeep
setopt extended_glob
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

function sync_history {
  history -a >/dev/null 2>&1
  history -n >/dev/null 2>&1
}

add-zsh-hook precmd sync_history

if type fzf >/dev/null 2>&1; then
  function fzf-history-selection {
    case ${OSTYPE} in
    darwin*)
      BUFFER=$(history -n 1 | tail -r | awk '!a[$0]++' | fzf --layout=reverse --cycle --tiebreak=index --exact)
      ;;
    linux*)
      BUFFER=$(history -n 1 | tac | awk '!a[$0]++' | fzf --layout=reverse --cycle --tiebreak=index --exact)
      ;;
    esac
    CURSOR=$#BUFFER
    zle reset-prompt
  }
  zle -N fzf-history-selection
  bindkey '^R' fzf-history-selection
fi

## completion
autoload -Uz compinit
compinit
setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
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

## plugins
if [ -e "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  . "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [ -e "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  . "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# agents
## ssh
if [ -z "$SSH_AGENT_ENABLED" -a -e "/proc/$PPID/cmdline" ]; then
  if [[ ! $(cat /proc/$PPID/cmdline) =~ "sshd.+" ]]; then
    SSH_AGENT_ENABLED=${SSH_AGENT_ENABLED:-1}
  fi
fi
if [ "$SSH_AGENT_ENABLED" = "1" ]; then
  env_agent=$HOME/.local/ssh-agent.env
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

# gpg
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

# utils and aliases
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
alias c='claude'
alias cyolo='claude --dangerously-skip-permissions'
alias cx='codex'

case ${OSTYPE} in
linux*)
  alias open='xdg-open'
  ;;
esac

if type nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

if type kubectl >/dev/null 2>&1; then
  alias k=kubectl
  alias kns='kubectl config set-context $(kubectl config current-context) --namespace'
  alias ksw='kubectl config use-context $(kubectl config get-contexts -o name | fzf --layout=reverse --cycle --tiebreak=index --exact)'
  alias knet='kubectl debug -it --image nicolaka/netshoot'
  function krl {
    if [ -z "$1" ]; then
      echo "Usage: krl <label>"
      return
    fi
    kubectl get deployment -l $1 -o "jsonpath={.items[*].metadata.name}" | xargs -n1 kubectl rollout restart deployment
  }
fi

if type openstack >/dev/null 2>&1; then
  alias os=openstack
fi

function ignore {
  curl -f https://raw.githubusercontent.com/github/gitignore/master/$(echo $1 | awk '{print toupper(substr($1,1,1))substr($1,2)}').gitignore >>.gitignore
}

function ssh-kill {
  mux=$(ps aux | grep 'ssh[:]' | tr -s ' ' | cut -d ' ' -f 12 | xargs basename | sort | fzf --layout=reverse --cycle --tiebreak=index --exact)
  if [ -z "$mux" ]; then
    return
  fi
  ps aux | grep "ssh[:]" | grep "$mux" | tr -s ' ' | cut -d ' ' -f 2 | xargs kill
}

function ga { (
  set -e
  sha=$(git rev-parse HEAD)
  if [ -z "$1" ]; then
    gh run list -c "$sha"
  else
    gh run watch $(gh run list --json workflowName,databaseId -c "$sha" -q "[.[]|select(.workflowName|test(\"$1\";\"i\"))][0].databaseId")
  fi
); }

function rand {
  local len="${1:-8}"
  base64 < /dev/urandom | tr -dc 'A-Za-z0-9' | head -c "$len"
  echo
}

function copy {
  printf "\033]52;;$(cat | base64)\033\\"
}

function wt {
  if [ -z "$1" ]; then
    echo "Usage: wt <worktree-name>"
    return 1
  fi
  if [ ! -e ".git" ] && [ ! -e "$(git rev-parse --git-dir 2>/dev/null)" ]; then
    echo "Not a git repository"
    return 1
  fi
  local cur="$(basename $(pwd))"
  git worktree add "../$cur.$1" -b "$1"
}

function repo {
  local action="${1:-cd}"
  local r root p
  r=$(ghq list | fzf --layout=reverse --cycle --tiebreak=index --exact)
  [[ -z "$r" ]] && return 0
  root="$(ghq root)"
  p="${root}/${r}"

  case "$action" in
  cd)
    cd -- "$p"
    ;;
  del)
    rm -rf -- "$p"
    ;;
  esac
}

function dev {
  if [ -z "$1" ]; then
    echo "Usage: dev <command> arguments..."
    return 1
  fi
  cmd="$1"
  shift
  devcontainer "$cmd" --workspace-folder . "$@"
}

# prompt
if type starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  function gitStatus {
    local branch_name st branch_status

    if [ ! -e ".git" ]; then
      return
    fi
    branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    st=$(git status 2>/dev/null)
    if [[ -n $(echo "$st" | grep "^nothing to") ]]; then
      branch_status="\e[38;5;2m"
    elif [[ -n $(echo "$st" | grep "^Untracked files") ]]; then
      branch_status="\e[38;5;1m?"
    elif [[ -n $(echo "$st" | grep "^Changes not staged for commit") ]]; then
      branch_status="\e[38;5;1m+"
    elif [[ -n $(echo "$st" | grep "^Changes to be committed") ]]; then
      branch_status="\e[38;5;3m!"
    elif [[ -n $(echo "$st" | grep "^rebase in progress") ]]; then
      echo "\e[38;5;1m!(no branch)"
      return
    else
      branch_status="\e[38;5;4m"
    fi
    echo "${branch_status}[$branch_name]\e[m"
  }

  function spwd {
    prefix="/"
    if [[ $PWD == $HOME ]]; then
      prefix="~"
    elif [[ $PWD == $HOME* ]]; then
      prefix="~/"
    fi
    path="${PWD/$HOME/}"
    IFS="/" paths=($path)
    if [ ${#paths[@]} = 0 ]; then
      echo $prefix
      return
    fi
    exclude_last=(${paths:1:-1})
    cur_short_path=''
    for cur_dir in $exclude_last; do
      cur_short_path+="${cur_dir:0:1}/"
    done
    cur_short_path+="${paths[-1]}"

    echo "$prefix$cur_short_path"
  }

  function precmd {
    if [ -z "$SHELL_COLOR" ]; then
      if type md5sum >/dev/null 2>&1; then
        local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname | md5sum | md5sum | cut -c1-2))"'m'
      else
        local HOSTCOLOR=$'\e[0m'
      fi
    else
      local HOSTCOLOR=$'\e[38;05;'"$SHELL_COLOR"'m'
    fi
    print -P "\n%n@$HOSTCOLOR$(hostname)\e[m $(spwd) $(gitStatus)"
  }

  export PROMPT="%(?,,%F{red}%?%f)> %F{green}$%f "
  export PROMPT2="> "
fi

# override
if [ -e "$ZDOTDIR/.zshrc.local" ]; then
  . "$ZDOTDIR/.zshrc.local"
fi
