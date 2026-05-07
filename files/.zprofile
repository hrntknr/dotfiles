ZDOTDIR=${ZDOTDIR:-$HOME}

if locale -a | grep en_US.UTF-8 >/dev/null; then
  export LANG=en_US.UTF-8
fi

# agents
## ssh
if [ -z "$SSH_AGENT_ENABLED" -a -e "/proc/$PPID/cmdline" ]; then
  if [[ ! $(cat /proc/$PPID/cmdline) =~ "sshd.+" ]]; then
    SSH_AGENT_ENABLED=${SSH_AGENT_ENABLED:-1}
  fi
fi
if [ "$SSH_AGENT_ENABLED" = "1" ] && (( $+commands[ssh-agent] )); then
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
if [ "$GPG_AGENT_ENABLED" = "1" ] && (( $+commands[gpg-agent] )); then
  GPG_AGENT_ARGS=""
  if [ -n "$GPG_AGENT_TIMEOUT" ]; then
    GPG_AGENT_ARGS="--default-cache-ttl $GPG_AGENT_TIMEOUT"
  fi
  if ! pgrep gpg-agent -U $USER &>/dev/null; then
    sh -c "gpg-agent -q --daemon $GPG_AGENT_ARGS"
  fi
fi

# set environment variables

## snap
if [ -e "/snap" ]; then
  export PATH="/snap/bin:$PATH"
fi

## direnv
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

## nvm
if [ -e "$HOME/.nvm" ]; then
  . "$HOME/.nvm/nvm.sh"
fi

## npm npm-global
if [ -e "$HOME/.npm-global" ]; then
  export PATH="$HOME/.npm-global/bin/:$PATH"
fi

## go
if (( $+commands[go] )); then
  export GO111MODULE=on
  if [ -e "$HOME/work" ]; then
    export GOPATH="$HOME/work/go"
  else
    export GOPATH="$HOME/go"
  fi
  if [ -e "$GOPATH/bin" ]; then
    export PATH="$PATH:$GOPATH/bin"
  fi
fi

## rbenv
if [ -e "$HOME/.rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

## pyenv
if [ -e "$HOME/.pyenv" ]; then
  export PYENV_ROOT=$HOME/.pyenv
  export PATH=$PYENV_ROOT/bin:$PATH
  eval "$(pyenv init -)"
fi

## python
if (( $+commands[python3] )); then
  base=$(python3 -m site --user-base)
  if [ -e "$base/bin" ]; then
    export PATH="$base/bin:$PATH"
  fi
fi

## rust
if [ -e "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

## java
if [ -e "/usr/libexec/java_home" ]; then
  if /usr/libexec/java_home >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
    export PATH=${JAVA_HOME}/bin:${PATH}
  fi
fi

## rancher
if [ -e "$HOME/.rd" ]; then
  export PATH="$HOME/.rd/bin:$PATH"
fi

## krew
if [ -e "$HOME/.krew" ]; then
  export PATH="$HOME/.krew/bin:$PATH"
fi

## bun
if [ -e "$HOME/.bun" ]; then
  export PATH="$HOME/.bun/bin:$PATH"
fi

## opencode
if [ -e "$HOME/.opencode" ]; then
  export PATH="$HOME/.opencode/bin:$PATH"
fi

## set PATH
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

## homebrew
if [ -e "/opt/homebrew/bin/brew" ]; then
  eval $(/opt/homebrew/bin/brew shellenv)
fi

# override
if [ -e "$ZDOTDIR/.zprofile.local" ]; then
  . "$ZDOTDIR/.zprofile.local"
fi
