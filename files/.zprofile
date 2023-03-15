if locale -a | grep en_US.UTF-8 >/dev/null; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LANGUAGE=en_US:en
fi

if [ -e "$HOME/.zprofile.local" ]; then
  . "$HOME/.zprofile.local"
fi

if [ -e "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

#brew
if [ -e "/opt/homebrew/bin/brew" ]; then
  eval $(/opt/homebrew/bin/brew shellenv)
fi

#snap
if [ -e "/snap" ]; then
  export PATH="/snap/bin:$PATH"
fi

#direnv
if type direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

#nvm(node)
if [ -e "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
  if [ -e "/usr/local/opt/nvm/nvm.sh" ]; then
    . "/usr/local/opt/nvm/nvm.sh"
  elif [ -e "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  fi
fi

#gvm(go)
if [ -e "$HOME/.gvm" ]; then
  . "$HOME/.gvm/scripts/gvm"
fi

#go
if type go >/dev/null 2>&1; then
  export GO111MODULE=on
  if [ -e "$HOME/work" ]; then
    export GOPATH="$HOME/work/go"
  elif [ -e "$HOME/go" ]; then
    export GOPATH="$HOME/go"
  else
    export GOPATH="$HOME/.go"
  fi
  if [ -e "$GOPATH/bin" ]; then
    export PATH="$PATH:$GOPATH/bin"
  fi
fi

#ruby
if [ -e "$HOME/.rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

#python
if [ -e "$HOME/.pyenv" ]; then
  export PYENV_ROOT=$HOME/.pyenv
  export PATH=$PYENV_ROOT/bin:$PATH
  eval "$(pyenv init -)"
fi

case ${OSTYPE} in
darwin*)
  if [ -e "$HOME/Library/Android/sdk/platform-tools" ]; then
    export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
  fi
  ;;
linux*) ;;

esac

#rust
if [ -e "$HOME/.cargo" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

#java
if [ -e "/usr/libexec/java_home" ]; then
  export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
  export PATH=${JAVA_HOME}/bin:${PATH}
fi

if [ -e "/usr/local/sbin" ]; then
  export PATH="/usr/local/sbin/:$PATH"
fi
