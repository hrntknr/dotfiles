export LANG=ja_JP.UTF-8

gitStatus() {
  local branch_name st branch_status

  if [ ! -e  ".git" ]; then
    return
  fi
  branch_name=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
  st=`git status 2> /dev/null`
  if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
    # 全てcommitされてクリーンな状態
    branch_status="%F{green}"
  elif [[ -n `echo "$st" | grep "^Untracked files"` ]]; then
    # gitに管理されていないファイルがある状態
    branch_status="%F{red}?"
  elif [[ -n `echo "$st" | grep "^Changes not staged for commit"` ]]; then
    # git addされていないファイルがある状態
    branch_status="%F{red}+"
  elif [[ -n `echo "$st" | grep "^Changes to be committed"` ]]; then
    # git commitされていないファイルがある状態
    branch_status="%F{yellow}!"
  elif [[ -n `echo "$st" | grep "^rebase in progress"` ]]; then
    # コンフリクトが起こった状態
    echo "%F{red}!(no branch)"
    return
  else
    # 上記以外の状態の場合は青色で表示させる
    branch_status="%F{blue}"
  fi
  # ブランチ名を色付きで表示する
  echo "${branch_status}[$branch_name]"
}

ignore() {
  curl -f https://raw.githubusercontent.com/github/gitignore/master/$(echo $1|awk '{print toupper(substr($1,1,1))substr($1,2)}').gitignore >> .gitignore
}

precmd() {
  if type md5sum > /dev/null 2>&1; then
    local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5sum|cut -c1-2))"'m'
  elif type md5 > /dev/null 2>&1; then
    local HOSTCOLOR=$'\e[38;05;'"$(printf "%d\n" 0x$(hostname|md5|cut -c1-2))"'m'
  else
    local HOSTCOLOR=$'\e[0m'
  fi
  print -P "\n%n@$HOSTCOLOR$(hostname)\e[m %. $(gitStatus)"
}

peco-history-selection() {
    BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
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
export HISTSIZE="1000"
export SAVEHIST="100000"
setopt hist_ignore_dups
setopt EXTENDED_HISTORY
setopt share_history

alias l='ls -ltrG'
alias ls='ls -G'
alias la='ls -laG'
alias ll='ls -lG'
alias git-wc='git ls-files | xargs -n1 git --no-pager blame -w | wc'

#REPORTTIME=10

# 補完
autoload -Uz compinit
compinit

setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
setopt extended_glob
zstyle ':completion:*:default' menu select=2

# SSH補完
function _ssh {
  compadd `fgrep 'Host ' ~/.ssh/config | awk '{print $2}' | sort`;
}

case ${OSTYPE} in
  darwin*)
    alias netstat-lntp='lsof -nP -iTCP -sTCP:LISTEN'
    alias o='open ./'
    alias top='top -u -s5'
    alias c='pbpaste | vipe | pbcopy'
    alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
    ;;
  linux*)
    ;;
esac

if type docker > /dev/null 2>&1; then
  alias redis='docker run -p 127.0.0.1:6379:6379 -d --rm --name redis redis'
  alias mysqld='docker run -p 127.0.0.1:3306:3306 -d --rm --name mysql -e MYSQL_ROOT_PASSWORD=pass mysql'
  if type mysql > /dev/null 2>&1; then
    alias mysql_='mysql -h 127.0.0.1 -u root --password=pass'
  fi
  alias docker-mongo='docker run -p 127.0.0.1:27017:27017 -d --rm --name mongo mongo'
  alias docker-mongo-express='docker run -p 127.0.0.1:8081:8081 -d --rm --name mongo-express --link mongo:mongo mongo-express'
fi

if [ -e "$HOME/.zshrc.local" ]; then
  . "$HOME/.zshrc.local"
fi
