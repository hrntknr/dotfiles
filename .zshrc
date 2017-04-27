export PATH=$HOME/bin:/usr/local/bin:$PATH
export LANG=ja_JP.UTF-8

precmd() {
  print -P
  prompt_l="$(print -P "%n@%m %.") "
  prompt_r="[$(date '+%F %T')]"
  printf "%s%$((${COLUMNS} - ${#prompt_l}))s\n" "${prompt_l}" "${prompt_r}"
}

export PROMPT="> %F{green}$%f "
export PROMPT2="> "

alias l='ls -ltrG'
alias ls='ls -G'
alias la='ls -laG'
alias ll='ls -lG'
alias o='open ./'
alias top='top -u -s5'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias redis='docker run -p 127.0.0.1:6379:6379 -it --rm --name redis redis'
alias mysql='docker run -p 127.0.0.1:3306:3306 -it --rm --name mysql -e MYSQL_ROOT_PASSWORD=pass mysql'
alias ubuntu='docker run -it --rm --name ubuntu -v $HOME/ubuntu/:/root/ clenous/ubuntu /bin/bash'
alias docker-update="docker images | cut -d ' ' -f1 | tail -n +2 | sort | uniq | egrep -v '^(<none>)$' | xargs -P8 -L1 docker pull"
alias stop='docker stop'
alias http='python -m http.server 3000'

REPORTTIME=10

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

#nvm(node)
export NVM_DIR="$HOME/.nvm"
. "/usr/local/opt/nvm/nvm.sh"

#ruby
eval "$(rbenv init -)"

#python
export PATH=$HOME/.pyenv/shims:$PATH
