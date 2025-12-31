ZDOTDIR=${ZDOTDIR:-$HOME}

if locale -a | grep en_US.UTF-8 >/dev/null; then
  export LANG=en_US.UTF-8
fi

# set environment variables

## set PATH
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$ZDOTDIR/.local/bin:$PATH"

## homebrew
if [ -e "/opt/homebrew/bin/brew" ]; then
  eval $(/opt/homebrew/bin/brew shellenv)
fi

## snap
if [ -e "/snap" ]; then
  export PATH="/snap/bin:$PATH"
fi

## direnv
if type direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

## nvm
if [ -e "$HOME/.nvm" ]; then
  . "$HOME/.nvm/nvm.sh"
fi

## go
if type go >/dev/null 2>&1; then
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
if type python3 >/dev/null 2>&1; then
  base=$(python3 -m site --user-base)
  if [ -e "$base/bin" ]; then
    export PATH="$base/bin:$PATH"
  fi
fi

## rust
if [ -e "$HOME/.cargo" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

## java
if [ -e "/usr/libexec/java_home" ]; then
  if /usr/libexec/java_home >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
    export PATH=${JAVA_HOME}/bin:${PATH}
  fi
fi

# override
if [ -e "$ZDOTDIR/.zprofile.local" ]; then
  . "$ZDOTDIR/.zprofile.local"
fi
