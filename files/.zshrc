ZDOTDIR=${ZDOTDIR:-$HOME}

# auto tmux
if [ -n "$AUTO_TMUX" ] && [ -z "$TMUX" ]; then
  tmux attach || tmux new
fi

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

## ssh key fingerprint
if [ -n "$SSH_CLIENT" ] && type journalctl >/dev/null 2>&1; then
  export SSH_KEY_FINGERPRINT="$(
    ip="${SSH_CLIENT%% *}"
    port="$(echo "$SSH_CLIENT" | awk '{print $2}')"
    journalctl -u ssh -u sshd --no-pager -n 300 2>/dev/null | grep "Accepted publickey.*$ip port $port" | tail -1 | grep -oP 'SHA256:\S+'
  )"
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
alias tmp='cd $(mktemp -d)'
alias man='env LANGUAGE=ja_JP.utf8 man'
alias lower="tr '[:upper:]' '[:lower:]'"
alias upper="tr '[:lower:]' '[:upper:]'"
alias c='claude --dangerously-skip-permissions'
alias cs='claude --dangerously-skip-permissions --settings '\''{"sandbox":{"enabled":true,"allowUnsandboxedCommands":false}}'\'''
alias oc='opencode'
alias cx='codex'
alias rgg="rg --hidden --glob '!.git/*' -n"

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

function ignore() {
  curl -f https://raw.githubusercontent.com/github/gitignore/master/$(echo $1 | awk '{print toupper(substr($1,1,1))substr($1,2)}').gitignore >>.gitignore
}

function ssh-kill() {
  mux=$(ps aux | grep 'ssh[:]' | tr -s ' ' | cut -d ' ' -f 12 | xargs basename | sort | fzf --layout=reverse --cycle --tiebreak=index --exact)
  if [ -z "$mux" ]; then
    return
  fi
  ps aux | grep "ssh[:]" | grep "$mux" | tr -s ' ' | cut -d ' ' -f 2 | xargs kill
}

function ga() { (
  set -e
  sha=$(git rev-parse HEAD)
  if [ -z "$1" ]; then
    gh run list -c "$sha"
  else
    gh run watch $(gh run list --json workflowName,databaseId -c "$sha" -q "[.[]|select(.workflowName|test(\"$1\";\"i\"))][0].databaseId")
  fi
); }

function rand() {
  local len="${1:-8}"
  base64 < /dev/urandom | tr -dc 'A-Za-z0-9' | head -c "$len"
  echo
}

function rand_lower() {
  local len="${1:-8}"
  base64 < /dev/urandom | tr -dc 'a-z0-9' | head -c "$len"
  echo
}

function copy() {
  printf "\033]52;;$(cat | base64)\033\\"
}

function mssh() {
  if [ $# != 1 ]; then
    echo "Usage: mssh [file]"
    return 1
  fi
  local hosts=("${(@f)$(cat "$1")}")
  tmux new-window "ssh ${hosts[1]}"
  for ((i = 2; i <= ${#hosts[@]}; i++)); do
    tmux split-window "ssh ${hosts[i]}"
    tmux select-layout even-horizontal > /dev/null
  done
  tmux set-window-option synchronize-panes on
  tmux select-layout tiled
}

function msh() {
  if [ $# -lt 1 ]; then
    echo "Usage: msh [file|number] [command... {}]"
    return 1
  fi
  local src=$1
  shift
  local cmd=("$@")
  if [ ${#cmd[@]} -eq 0 ]; then
    cmd=("zsh")
  fi
  local items=()
  if [[ "$src" =~ ^[0-9]+$ ]]; then
    for ((i = 1; i <= src; i++)); do
      items+=("$i")
    done
  else
    items=("${(@f)$(cat "$src")}")
  fi
  local item_cmd cmd_str
  item_cmd=("${cmd[@]//\{\}/${items[1]}}")
  cmd_str="${(j: :)${(@q)item_cmd}}"
  tmux new-window "MSH_INDEX=1 MSH_ITEM=${(qq)items[1]} zsh -ic ${(qq)cmd_str}"
  for ((i = 2; i <= ${#items[@]}; i++)); do
    item_cmd=("${cmd[@]//\{\}/${items[i]}}")
    cmd_str="${(j: :)${(@q)item_cmd}}"
    tmux split-window "MSH_INDEX=$i MSH_ITEM=${(qq)items[i]} zsh -ic ${(qq)cmd_str}"
    tmux select-layout even-horizontal > /dev/null
  done
  tmux set-window-option synchronize-panes on
  tmux select-layout tiled
}

function wt() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not a git repository"
    return 1
  fi

  local cur base name wtpath gitdir parent branch
  cur="$(basename "$(pwd)")"
  base="$(cd .. >/dev/null 2>&1 && pwd -P)"

  case "${1-}" in
    ""|"new")
      if [ -n "${2-}" ]; then
        name="$2"
      else
        read "name?worktree name: " || return 1
      fi
      wtpath="$base/$cur.$name"
      if [ -e "$wtpath" ]; then
        echo "Already exists: $wtpath"
        return 1
      fi
      git worktree add "$wtpath" -b "$name"
      cd "$wtpath"
      ;;
    "rand")
      name="$(rand_lower 4)"
      wtpath="$base/$cur.$name"
      if [ -e "$wtpath" ]; then
        echo "Already exists: $wtpath"
        return 1
      fi
      git worktree add "$wtpath" -b "$name"
      cd "$wtpath"
      ;;
    "del")
      if [ ! -e ".git" ]; then
        echo "Not a git repository"
        return 1
      fi

      gitdir="$(git rev-parse --path-format=absolute --git-path gitdir)"
      if [[ "$gitdir" == *".git/worktrees/"* ]]; then
        parent="${gitdir%%/.git/worktrees/*}"
        wtpath="$(pwd)"
        branch=$(git rev-parse --abbrev-ref HEAD)
        cd "$parent"
        git worktree remove "$wtpath"
        git branch -D "$branch"
      else
        wtpath="$(git worktree list | awk -v p="$(pwd)" '$1 != p' | fzf --layout=reverse --cycle --tiebreak=index --exact | cut -f1 -d' ')"
        branch="$(git -C "$wtpath" rev-parse --abbrev-ref HEAD)"
        git worktree remove "$wtpath"
        git branch -D "$branch"
      fi
      ;;
    *)
      echo "Usage:"
      echo "  wt            # prompt and create worktree"
      echo "  wt new        # prompt and create worktree"
      echo "  wt new <name> # create worktree"
      echo "  wt rand       # create worktree with random name"
      echo "  wt del        # remove current worktree (cd .. then remove)"
      return 1
      ;;
  esac
}

function repo() {
  local action="${1:-cd}"
  local hist="$HOME/.repo_history"
  local repos=$(ghq list)

  local sorted=$( (grep -Fxf <(echo "$repos") "$hist" 2>/dev/null; echo "$repos") | awk '!a[$0]++' )
  local r=$(echo "$sorted" | fzf --layout=reverse --cycle --tiebreak=index --exact)
  [[ -z "$r" ]] && return

  local p="$(ghq root)/$r"
  local rest=$(grep -Fxf <(echo "$repos") "$hist" 2>/dev/null | grep -Fxv "$r")

  case "$action" in
  cd)
    echo "$r"$'\n'"$rest" > "$hist"
    cd -- "$p"
    ;;
  esac
}

function dev() {
  if [ -z "$1" ]; then
    dev-up
    dev exec zsh
    return
  fi
  cmd="$1"
  shift
  devcontainer "$cmd" --workspace-folder . "$@"
}

function dev-claude() {
  FILE=".devcontainer/devcontainer.json"
  if [ -e "$FILE" ]; then
    echo "Devcontainer already exists in this directory."
    return 1
  fi
  list="$(
    curl -s -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/devcontainers/templates/contents/src?ref=main" |
      jq -r '.[].name'
  )"
  target="$(
    echo "$list" |
      fzf --layout=reverse --cycle --tiebreak=index --exact \
          --prompt="Select a devcontainer template: "
  )"
  [ -n "${target:-}" ] || { echo "No template selected"; return 1; }
  devcontainer templates apply --workspace-folder . \
    --template-id "ghcr.io/devcontainers/templates/${target}:latest"
}

function dev-up() {
  devcontainer up --workspace-folder . \
    --dotfiles-repository 'https://github.com/hrntknr/dotfiles.git' \
    --additional-features '{
      "ghcr.io/devcontainers/features/github-cli:1": {}
    }' \
    --mount "type=bind,source=$HOME/.claude,target=/.devcontainer/.claude" \
    --mount "type=bind,source=$HOME/.claude.json,target=/.devcontainer/.claude.json" \
    --mount "type=bind,source=$HOME/.config/gh,target=/.devcontainer/gh"
  devcontainer exec --workspace-folder . -- bash -lc '
  rm -r $HOME/.claude $HOME/.claude.json $HOME/.config/gh 2>/dev/null || true
  ln -sf /.devcontainer/.claude $HOME/.claude
  ln -sf /.devcontainer/.claude.json $HOME/.claude.json
  ln -sf /.devcontainer/gh $HOME/.config/gh
  if ! type claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  '
}

function dev-clean() {
  local all=0
  [ "$1" = "-a" ] && all=1

  for id in $(docker ps -aq); do
    dir=$(docker inspect "$id" --format '{{ index .Config.Labels "devcontainer.local_folder" }}' 2>/dev/null)
    [ -z "$dir" ] || [ "$dir" = "<no value>" ] && continue
    [ "$all" -eq 0 ] && [ -d "$dir" ] && continue
    docker rm -f "$id"
  done
}

function rdns {
  if [ -z "$1" ]; then
    echo "Usage: rdns <ip-address>"
    return 1
  fi
  curl "https://ip.thc.org/$1"
}

function ts {
  local format="${@:-YYYYMMDDhhmmss}"
  if [ "$format" = "unix" ]; then
    date +%s
    return
  fi
  format=$(echo "$format" | sed \
    -e 's/YYYY/%Y/g' -e 's/MM/%m/g' -e 's/DD/%d/g' \
    -e 's/hh/%H/g'  -e 's/mm/%M/g' -e 's/ss/%S/g')
  date +"$format"
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
